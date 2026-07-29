import MapKit
import SwiftUI

struct VendorWorkingMapView: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    @StateObject private var mapModel = VendorMapViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                VendorBusinessMapLayer(
                    mapModel: mapModel,
                    snapshot: mapSnapshot
                )
                .equatable()

                mapControls
                    .padding(.top, 8)
                    .padding(.trailing, 12)

                VStack {
                    Spacer()
                    bottomPanel
                }
            }
            .navigationTitle("map.area.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Map Style", selection: $mapModel.mapStyle) {
                            ForEach(VendorMapStyleOption.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                    } label: {
                        Image(systemName: "map")
                    }
                }
            }
        }
        .onAppear {
            mapModel.configure(area: liveSession.selectedOperatingArea)
            mapModel.refreshRoute(stops: liveSession.routeStops)
        }
        .onChange(of: liveSession.selectedOperatingArea) { _, area in
            mapModel.configure(area: area)
        }
        .onChange(of: liveSession.routeStops) { _, stops in
            mapModel.refreshRoute(stops: stops)
            mapModel.syncFollowMode(
                serviceMode: liveSession.serviceMode,
                operatingArea: liveSession.selectedOperatingArea,
                routeStops: stops
            )
        }
        .onChange(of: liveSession.liveElapsedSeconds) { _, _ in
            guard mapModel.followVendor else { return }
            mapModel.syncFollowMode(
                serviceMode: liveSession.serviceMode,
                operatingArea: liveSession.selectedOperatingArea,
                routeStops: liveSession.routeStops
            )
        }
    }

    private var mapSnapshot: VendorBusinessMapSnapshot {
        VendorBusinessMapSnapshot(
            serviceMode: liveSession.serviceMode,
            operatingArea: liveSession.selectedOperatingArea,
            routeStops: liveSession.routeStops,
            demandClusters: liveSession.demandClusters,
            isLive: liveSession.state == .live,
            mapStyle: mapModel.mapStyle,
            routePolyline: mapModel.routePolyline,
            followVendor: mapModel.followVendor,
            geocodedAreaCoordinate: mapModel.geocodedAreaCoordinate ?? liveSession.geocodedAreaCoordinate
        )
    }

    private var mapControls: some View {
        VStack(spacing: 8) {
            mapControlButton(icon: mapModel.followVendor ? "location.fill" : "location") {
                mapModel.followVendor.toggle()
                if mapModel.followVendor {
                    mapModel.syncFollowMode(
                        serviceMode: liveSession.serviceMode,
                        operatingArea: liveSession.selectedOperatingArea,
                        routeStops: liveSession.routeStops
                    )
                }
            }
            mapControlButton(icon: "scope") {
                mapModel.followVendor = false
                let coord = mapModel.vendorCoordinate(
                    serviceMode: liveSession.serviceMode,
                    operatingArea: liveSession.selectedOperatingArea,
                    routeStops: liveSession.routeStops
                )
                mapModel.recenter(on: coord)
            }
        }
    }

    private func mapControlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.bold))
                .frame(width: 40, height: 40)
                .background(AppTheme.card.opacity(0.95))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bottomPanel: some View {
        if let selected = mapModel.selectedItem {
            selectionCard(selected)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if !liveSession.routeRecommendations.isEmpty {
            recommendationsCard
                .padding()
        } else if let cluster = liveSession.demandClusters.first {
            clusterPreview(cluster)
                .padding()
        }
    }

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("demand.tips.title")
                .font(.headline.weight(.bold))
            ForEach(liveSession.routeRecommendations.prefix(2)) { rec in
                HStack {
                    Text(rec.message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    if let clusterID = rec.clusterID,
                       let cluster = liveSession.demandClusters.first(where: { $0.id == clusterID }) {
                        Button("route.add_stop") {
                            liveSession.insertClusterAfterCurrent(cluster)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.primary)
                    }
                }
            }
        }
        .padding(12)
        .background(AppTheme.card.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func clusterPreview(_ cluster: DemandCluster) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cluster.peopleWaitingText)
                    .font(.headline.weight(.bold))
                Spacer()
            }
            Text(cluster.neighborhoodName)
                .font(.subheadline.weight(.semibold))
            if !cluster.productHints.isEmpty {
                Text(cluster.productHints.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            HStack {
                Button("map.look") {
                    mapModel.selectedItem = .cluster(cluster)
                }
                .buttonStyle(.bordered)
                Button("route.add_stop") {
                    liveSession.addDemandCluster(cluster)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
            }
        }
        .padding(12)
        .background(AppTheme.card.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            mapModel.centerOnCluster(cluster)
        }
    }

    @ViewBuilder
    private func selectionCard(_ selection: VendorMapSelection) -> some View {
        switch selection {
        case .cluster(let cluster):
            clusterPreview(cluster)
        case .stop(let stop):
            VStack(alignment: .leading, spacing: 6) {
                Text(stop.title).font(.headline)
                Text(stop.landmark).font(.caption).foregroundStyle(AppTheme.textSecondary)
                if let notes = stop.notes, !notes.isEmpty {
                    Text(notes).font(.caption)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        case .recommendation(let rec):
            Text(rec.message)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct VendorBusinessMapSnapshot: Equatable {
    var serviceMode: VendorServiceMode
    var operatingArea: ChennaiArea
    var routeStops: [VendorRouteStopPlan]
    var demandClusters: [DemandCluster]
    var isLive: Bool
    var mapStyle: VendorMapStyleOption
    var routePolyline: [CodableCoordinate]
    var followVendor: Bool
    var geocodedAreaCoordinate: CodableCoordinate?
}

private struct VendorBusinessMapLayer: View, Equatable {
    @ObservedObject var mapModel: VendorMapViewModel
    let snapshot: VendorBusinessMapSnapshot

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.snapshot == rhs.snapshot && lhs.mapModel.mapStyle == rhs.mapModel.mapStyle
    }

    var body: some View {
        Map(position: $mapModel.cameraPosition, selection: $mapModel.selectedItem) {
            if snapshot.routePolyline.count >= 2 {
                MapPolyline(coordinates: snapshot.routePolyline.map(\.mapCoordinate))
                    .stroke(AppTheme.primary, lineWidth: 4)
            }

            vendorAnnotation
            routeMarkers
            clusterMarkers
        }
        .mapStyle(snapshot.mapStyle.mapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
            MapPitchToggle()
            MapUserLocationButton()
        }
        .onAppear { initialCamera() }
        .onChange(of: snapshot.operatingArea) { _, _ in
            guard !snapshot.followVendor else { return }
            if let coord = snapshot.geocodedAreaCoordinate {
                mapModel.recenter(on: coord.mapCoordinate, span: snapshot.operatingArea.neighborhoodMapSpan, animated: true)
            }
        }
        .onMapCameraChange(frequency: .onEnd) { _ in
            if snapshot.followVendor {
                mapModel.followVendor = false
            }
        }
    }

    @MapContentBuilder
    private var vendorAnnotation: some MapContent {
        let coordinate = vendorCoordinate
        Annotation("business.map.you", coordinate: coordinate) {
            VStack(spacing: 4) {
                Circle()
                    .fill(AppTheme.primary)
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: snapshot.serviceMode.icon)
                            .foregroundStyle(.white)
                    }
                Text(snapshot.isLive ? "LIVE" : "Ready")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.card)
                    .clipShape(Capsule())
            }
        }
    }

    @MapContentBuilder
    private var routeMarkers: some MapContent {
        ForEach(snapshot.routeStops) { stop in
            Marker(stop.title, coordinate: stop.coordinate.mapCoordinate)
                .tint(stop.isCurrent ? AppTheme.primary : (stop.isCompleted ? .gray : AppTheme.info))
                .tag(VendorMapSelection.stop(stop))
        }
    }

    @MapContentBuilder
    private var clusterMarkers: some MapContent {
        ForEach(snapshot.demandClusters) { cluster in
            Annotation(cluster.neighborhoodName, coordinate: cluster.coordinate.mapCoordinate) {
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .fill(clusterColor(cluster.level))
                            .frame(width: 34, height: 34)
                        Text("\(cluster.customerCount)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    Text(cluster.level.emoji)
                        .font(.caption2)
                }
            }
            .tag(VendorMapSelection.cluster(cluster))
        }
    }

    private var vendorCoordinate: CLLocationCoordinate2D {
        mapModel.vendorCoordinate(
            serviceMode: snapshot.serviceMode,
            operatingArea: snapshot.operatingArea,
            routeStops: snapshot.routeStops
        )
    }

    private func initialCamera() {
        if let coord = snapshot.geocodedAreaCoordinate {
            mapModel.recenter(on: coord.mapCoordinate, span: snapshot.operatingArea.neighborhoodMapSpan, animated: false)
        }
    }

    private func clusterColor(_ level: DemandLevel) -> Color {
        switch level {
        case .high: return AppTheme.danger
        case .medium: return AppTheme.accent
        case .low: return AppTheme.info
        }
    }
}
