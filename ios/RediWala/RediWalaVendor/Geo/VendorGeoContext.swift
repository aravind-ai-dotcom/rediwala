import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// Vendor-side GeoContext bridge. Product features use this — not CoreLocation.
@MainActor
final class VendorGeoContext: ObservableObject {
    static let shared = VendorGeoContext()

    @Published var mode: GeoLocationModeVendor = .demo {
        didSet { persist(); refresh() }
    }
    @Published var operatingArea: ChennaiArea {
        didSet { refresh(); persist() }
    }
    @Published private(set) var coordinate: CLLocationCoordinate2D
    @Published private(set) var radiusMeters: Double = 3_200
    @Published private(set) var cameraPosition: MapCameraPosition
    @Published private(set) var neighborhoodId: String = ""

    private let modeKey = "vendor.geo.mode.v1"
    private let areaKey = "vendor.geo.area.v1"

    private init() {
        let area = UserDefaults.standard.string(forKey: areaKey)
            .flatMap(ChennaiArea.init(rawValue:)) ?? .westMambalam
        let mode = UserDefaults.standard.string(forKey: modeKey)
            .flatMap(GeoLocationModeVendor.init(rawValue:)) ?? .demo
        let seed = area.seedCoordinate.mapCoordinate
        self.operatingArea = area
        self.mode = mode
        self.coordinate = seed
        self.neighborhoodId = area.firebaseID
        self.cameraPosition = .region(
            MKCoordinateRegion(
                center: seed,
                span: MKCoordinateSpan(
                    latitudeDelta: area.neighborhoodMapSpan,
                    longitudeDelta: area.neighborhoodMapSpan
                )
            )
        )
        refresh()
    }

    func selectArea(_ area: ChennaiArea, recenter: Bool = true) {
        operatingArea = area
        if recenter { returnToNeighborhood() }
    }

    func returnToNeighborhood() {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: operatingArea.neighborhoodMapSpan,
                    longitudeDelta: operatingArea.neighborhoodMapSpan
                )
            )
        )
    }

    func zoomToRoute(center: CLLocationCoordinate2D, span: Double = 0.008) {
        cameraPosition = .region(
            MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
        )
    }

    func zoomToVendor(coordinate: CLLocationCoordinate2D, span: Double = 0.0035) {
        cameraPosition = .region(
            MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
        )
    }

    private func refresh() {
        coordinate = operatingArea.seedCoordinate.mapCoordinate
        neighborhoodId = operatingArea.firebaseID
        radiusMeters = 3_200
        if mode == .demo {
            // Demo is GPS-independent by design.
        }
    }

    private func persist() {
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
        UserDefaults.standard.set(operatingArea.rawValue, forKey: areaKey)
    }
}

enum GeoLocationModeVendor: String, CaseIterable, Identifiable, Codable {
    case demo
    case liveGPS
    case hybrid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .demo: return "Demo"
        case .liveGPS: return "Live GPS"
        case .hybrid: return "Hybrid"
        }
    }
}

// MARK: - Future AI extension points (Vendor)

protocol VendorOpportunityEngine {
    func evaluateOperatingArea(_ area: ChennaiArea) async -> [String]
}

protocol VendorRouteOptimizationEngine {
    func optimize(stops: [VendorRouteStopPlan]) async -> [VendorRouteStopPlan]
}

protocol VendorDemandForecastEngine {
    func forecast(area: ChennaiArea) async -> [(category: String, score: Double)]
}
