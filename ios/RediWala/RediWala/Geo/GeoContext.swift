import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// Central geospatial intelligence hub.
/// All product features must obtain location through GeoContext — never CoreLocation directly.
@MainActor
final class GeoContext: ObservableObject {
    static let shared = GeoContext()

    // MARK: Published state

    @Published var mode: GeoLocationMode {
        didSet { persist(); refreshDerivedState() }
    }

    @Published private(set) var city: GeoCity
    @Published private(set) var neighborhood: NeighborhoodDefinition
    @Published private(set) var regionId: String
    @Published private(set) var bounds: GeoBounds
    @Published private(set) var coordinate: CLLocationCoordinate2D
    @Published private(set) var radiusMeters: Double
    @Published private(set) var cameraIntent: GeoCameraIntent = .neighborhood
    @Published private(set) var cameraPosition: MapCameraPosition
    @Published private(set) var isDemo: Bool = true

    /// Optional GPS sample when mode is live/hybrid. Never read CoreLocation outside this type.
    @Published private(set) var deviceCoordinate: CLLocationCoordinate2D?

    private let modeKey = "geo.context.mode.v1"
    private let neighborhoodKey = "geo.context.neighborhood.v1"
    private let cityKey = "geo.context.city.v1"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let savedMode = UserDefaults.standard.string(forKey: modeKey)
            .flatMap(GeoLocationMode.init(rawValue:)) ?? .demo
        let legacyPilot = CustomerNeighborhoodStore.shared.homeNeighborhood
        let savedHoodId = UserDefaults.standard.string(forKey: neighborhoodKey)
            ?? FirebaseIDMap.firebaseID(for: legacyPilot)
        let hood = NeighborhoodCatalog.neighborhood(id: savedHoodId)
            ?? NeighborhoodCatalog.defaultDemoNeighborhood
        let city = NeighborhoodCatalog.cities.first { $0.id == hood.cityId } ?? NeighborhoodCatalog.chennai

        self.mode = savedMode
        self.city = city
        self.neighborhood = hood
        self.regionId = "\(city.id)/\(hood.id)"
        self.bounds = hood.bounds
        self.coordinate = hood.center
        self.radiusMeters = hood.visibleRadiusMeters
        self.cameraPosition = .region(hood.mapRegion)
        self.isDemo = savedMode == .demo
        refreshDerivedState()
        bindLegacyNeighborhoodStore()
    }

    // MARK: - Public API

    var queryScope: GeoQueryScope {
        GeoQueryScope(
            cityId: city.id,
            neighborhoodId: neighborhood.id,
            center: coordinate,
            radiusMeters: radiusMeters,
            categoryRawValues: neighborhood.suggestedCategories,
            availability: .any
        )
    }

    func queryScope(
        categories: [String] = [],
        availability: GeoQueryScope.GeoAvailabilityFilter = .any,
        radiusMeters: Double? = nil
    ) -> GeoQueryScope {
        GeoQueryScope(
            cityId: city.id,
            neighborhoodId: neighborhood.id,
            center: coordinate,
            radiusMeters: radiusMeters ?? self.radiusMeters,
            categoryRawValues: categories.isEmpty ? neighborhood.suggestedCategories : categories,
            availability: availability
        )
    }

    func setMode(_ mode: GeoLocationMode) {
        self.mode = mode
    }

    func selectCity(_ city: GeoCity) {
        self.city = city
        if let first = NeighborhoodCatalog.neighborhoods(inCity: city.id).first {
            selectNeighborhood(first, recenter: true)
        }
        persist()
    }

    func selectNeighborhood(_ definition: NeighborhoodDefinition, recenter: Bool = true) {
        neighborhood = definition
        if let cityMatch = NeighborhoodCatalog.cities.first(where: { $0.id == definition.cityId }) {
            city = cityMatch
        }
        regionId = "\(city.id)/\(definition.id)"
        bounds = definition.bounds
        radiusMeters = definition.visibleRadiusMeters
        refreshDerivedState()
        CustomerNeighborhoodStore.shared.applyFromGeoContext(definition.asPilotNeighborhood())
        if recenter {
            returnToNeighborhood()
        }
        persist()
    }

    func selectPilotNeighborhood(_ pilot: PilotNeighborhood, recenter: Bool = true) {
        let id = FirebaseIDMap.firebaseID(for: pilot)
        if let definition = NeighborhoodCatalog.neighborhood(id: id) {
            selectNeighborhood(definition, recenter: recenter)
        }
    }

    /// Maps follow GeoContext — never auto-follow the user.
    func returnToNeighborhood() {
        cameraIntent = .neighborhood
        cameraPosition = .region(neighborhood.mapRegion)
        refreshDerivedState()
    }

    func resetCamera() {
        returnToNeighborhood()
    }

    func zoomToVendor(latitude: Double, longitude: Double, span: Double = 0.0035) {
        cameraIntent = .vendor(coordinateLatitude: latitude, coordinateLongitude: longitude, span: span)
        cameraPosition = .region(cameraIntent.region)
    }

    func zoomToRoute(centerLatitude: Double, centerLongitude: Double, span: Double = 0.008) {
        cameraIntent = .route(centerLatitude: centerLatitude, centerLongitude: centerLongitude, span: span)
        cameraPosition = .region(cameraIntent.region)
    }

    func zoomToSearch(centerLatitude: Double, centerLongitude: Double, span: Double = 0.01) {
        cameraIntent = .search(centerLatitude: centerLatitude, centerLongitude: centerLongitude, span: span)
        cameraPosition = .region(cameraIntent.region)
    }

    func applyManualCamera(_ region: MKCoordinateRegion) {
        cameraIntent = .custom(
            centerLatitude: region.center.latitude,
            centerLongitude: region.center.longitude,
            latitudeDelta: region.span.latitudeDelta,
            longitudeDelta: region.span.longitudeDelta
        )
        cameraPosition = .region(region)
    }

    /// Called only from DeviceGeoSource — never from feature ViewModels.
    func ingestDeviceCoordinate(_ coordinate: CLLocationCoordinate2D?) {
        deviceCoordinate = coordinate
        refreshDerivedState()
    }

    func isWithinActiveNeighborhood(_ latitude: Double, _ longitude: Double) -> Bool {
        let point = CLLocation(latitude: latitude, longitude: longitude)
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return point.distance(from: origin) <= radiusMeters
    }

    func distanceMeters(toLatitude latitude: Double, longitude: Double) -> Int {
        let a = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let b = CLLocation(latitude: latitude, longitude: longitude)
        return Int(a.distance(from: b))
    }

    // MARK: - Private

    private func refreshDerivedState() {
        isDemo = mode == .demo
        switch mode {
        case .demo:
            coordinate = neighborhood.center
        case .liveGPS:
            coordinate = deviceCoordinate ?? neighborhood.center
        case .hybrid:
            // Neighborhood override wins for product intelligence; GPS is informational.
            coordinate = neighborhood.center
        }
        bounds = neighborhood.bounds
        radiusMeters = neighborhood.visibleRadiusMeters
        if case .neighborhood = cameraIntent {
            cameraPosition = .region(neighborhood.mapRegion)
        }
    }

    private func persist() {
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
        UserDefaults.standard.set(neighborhood.id, forKey: neighborhoodKey)
        UserDefaults.standard.set(city.id, forKey: cityKey)
    }

    private func bindLegacyNeighborhoodStore() {
        CustomerNeighborhoodStore.shared.$homeNeighborhood
            .dropFirst()
            .sink { [weak self] pilot in
                guard let self else { return }
                let id = FirebaseIDMap.firebaseID(for: pilot)
                guard self.neighborhood.id != id,
                      let definition = NeighborhoodCatalog.neighborhood(id: id) else { return }
                self.neighborhood = definition
                self.regionId = "\(self.city.id)/\(definition.id)"
                self.refreshDerivedState()
            }
            .store(in: &cancellables)
    }
}
