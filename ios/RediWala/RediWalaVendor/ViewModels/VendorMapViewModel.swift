import Combine
import MapKit
import SwiftUI

enum VendorMapStyleOption: String, CaseIterable, Identifiable {
    case standard
    case satellite
    case hybrid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }
}

enum VendorMapSelection: Equatable, Hashable, Identifiable {
    case cluster(DemandCluster)
    case stop(VendorRouteStopPlan)
    case recommendation(RouteRecommendation)

    var id: String {
        switch self {
        case .cluster(let c): return "cluster_\(c.id)"
        case .stop(let s): return "stop_\(s.id)"
        case .recommendation(let r): return "rec_\(r.id)"
        }
    }
}

/// Isolated map state — immune to the 1-second live timer.
@MainActor
final class VendorMapViewModel: ObservableObject {
    @Published var mapStyle: VendorMapStyleOption = .standard
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var followVendor = false
    @Published var routePolyline: [CodableCoordinate] = []
    @Published var selectedItem: VendorMapSelection?
    @Published var geocodedAreaCoordinate: CodableCoordinate?

    private var routeRefreshTask: Task<Void, Never>?

    func configure(area: ChennaiArea) {
        VendorGeoContext.shared.selectArea(area, recenter: false)
        Task {
            let coord = await VendorGeocodingService.shared.coordinate(for: area)
            geocodedAreaCoordinate = coord
            if !followVendor {
                recenter(on: coord.mapCoordinate, span: area.neighborhoodMapSpan, animated: false)
                VendorGeoContext.shared.zoomToVendor(coordinate: coord.mapCoordinate, span: area.neighborhoodMapSpan)
            }
        }
    }

    func refreshRoute(stops: [VendorRouteStopPlan]) {
        // Instant circuit preview from waypoints while road routing resolves.
        let active = stops.filter { !$0.isCompleted }
        if active.count >= 2 {
            var preview = active.map(\.coordinate)
            if let first = preview.first, let last = preview.last,
               first.latitude != last.latitude || first.longitude != last.longitude {
                preview.append(first)
            }
            routePolyline = preview
        } else {
            routePolyline = active.map(\.coordinate)
        }

        routeRefreshTask?.cancel()
        routeRefreshTask = Task {
            let line = await VendorRouteDirectionService.shared.polyline(for: stops)
            guard !Task.isCancelled else { return }
            if line.count >= 2 {
                routePolyline = line
            }
            if let first = stops.first {
                VendorGeoContext.shared.zoomToRoute(center: first.coordinate.mapCoordinate)
            }
        }
    }

    func recenter(on coordinate: CLLocationCoordinate2D, span: Double = 0.008, animated: Bool = true) {
        VendorGeoContext.shared.zoomToVendor(coordinate: coordinate, span: span)
        let region = MapCameraPosition.region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
        )
        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = region
            }
        } else {
            cameraPosition = region
        }
    }

    func centerOnCluster(_ cluster: DemandCluster) {
        followVendor = false
        recenter(on: cluster.coordinate.mapCoordinate, span: cluster.neighborhood.streetMapSpan)
        selectedItem = .cluster(cluster)
    }

    func vendorCoordinate(
        serviceMode: VendorServiceMode,
        operatingArea: ChennaiArea,
        routeStops: [VendorRouteStopPlan]
    ) -> CLLocationCoordinate2D {
        if serviceMode == .stationary {
            return (geocodedAreaCoordinate ?? operatingArea.seedCoordinate).mapCoordinate
        }
        if let current = routeStops.first(where: { $0.isCurrent && !$0.isCompleted }) {
            return current.coordinate.mapCoordinate
        }
        return (geocodedAreaCoordinate ?? operatingArea.seedCoordinate).mapCoordinate
    }

    func syncFollowMode(
        serviceMode: VendorServiceMode,
        operatingArea: ChennaiArea,
        routeStops: [VendorRouteStopPlan]
    ) {
        guard followVendor else { return }
        let coord = vendorCoordinate(serviceMode: serviceMode, operatingArea: operatingArea, routeStops: routeStops)
        recenter(on: coord, span: operatingArea.neighborhoodMapSpan, animated: true)
    }
}
