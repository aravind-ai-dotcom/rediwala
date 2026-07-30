import CoreLocation
import Foundation
import MapKit

// MARK: - Location Modes

enum GeoLocationMode: String, CaseIterable, Identifiable, Codable {
    case demo
    case liveGPS
    case hybrid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .demo: return "Demo Mode"
        case .liveGPS: return "Live GPS"
        case .hybrid: return "Hybrid"
        }
    }

    var subtitle: String {
        switch self {
        case .demo: return "Virtual neighborhoods — works anywhere, including Simulator."
        case .liveGPS: return "Uses device location when available."
        case .hybrid: return "GPS with neighborhood override."
        }
    }
}

// MARK: - City / Region

struct GeoCity: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let countryCode: String
    let countryName: String
    let defaultTimezoneIdentifier: String
}

struct GeoBounds: Hashable, Codable {
    var southWestLatitude: Double
    var southWestLongitude: Double
    var northEastLatitude: Double
    var northEastLongitude: Double

    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (southWestLatitude + northEastLatitude) / 2,
            longitude: (southWestLongitude + northEastLongitude) / 2
        )
    }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= southWestLatitude
            && coordinate.latitude <= northEastLatitude
            && coordinate.longitude >= southWestLongitude
            && coordinate.longitude <= northEastLongitude
    }

    var mapRect: MKMapRect {
        let sw = MKMapPoint(CLLocationCoordinate2D(latitude: southWestLatitude, longitude: southWestLongitude))
        let ne = MKMapPoint(CLLocationCoordinate2D(latitude: northEastLatitude, longitude: northEastLongitude))
        return MKMapRect(
            x: min(sw.x, ne.x),
            y: min(sw.y, ne.y),
            width: abs(ne.x - sw.x),
            height: abs(ne.y - sw.y)
        )
    }
}

// MARK: - Neighborhood Definition (configuration, not hardcoded feature logic)

struct NeighborhoodDefinition: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let displayNameLocalizedKey: String
    let cityId: String
    let countryCode: String
    let centerLatitude: Double
    let centerLongitude: Double
    let defaultZoomSpan: Double
    let visibleRadiusMeters: Double
    let serviceRadiusMeters: Double
    let primaryStreets: [String]
    let landmarks: [String]
    let bounds: GeoBounds
    let demoPopulation: Int
    let vendorCapacity: Int
    let suggestedCategories: [String]

    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: defaultZoomSpan, longitudeDelta: defaultZoomSpan)
        )
    }

    var streetLevelRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: defaultZoomSpan * 0.35, longitudeDelta: defaultZoomSpan * 0.35)
        )
    }

    /// Bridge to legacy PilotNeighborhood when id matches.
    func asPilotNeighborhood() -> PilotNeighborhood {
        switch id {
        case "t_nagar": return .tNagar
        case "west_mambalam": return .westMambalam
        case "thiruvanmiyur": return .thiruvanmiyur
        case "adyar": return .adyar
        case "velachery": return .velachery
        case "besant_nagar": return .besantNagar
        case "anna_nagar": return .annaNagar
        case "kodambakkam": return .kodambakkam
        case "ashok_nagar": return .ashokNagar
        case "mylapore": return .mylapore
        case "triplicane": return .triplicane
        case "saidapet": return .saidapet
        case "ecr": return .ecr
        case "omr": return .omr
        default: return FirebaseIDMap.neighborhood(fromFirebase: id)
        }
    }
}

// MARK: - Camera Intent

enum GeoCameraIntent: Equatable {
    case neighborhood
    case vendor(coordinateLatitude: Double, coordinateLongitude: Double, span: Double = 0.0035)
    case route(centerLatitude: Double, centerLongitude: Double, span: Double = 0.008)
    case search(centerLatitude: Double, centerLongitude: Double, span: Double = 0.01)
    case custom(centerLatitude: Double, centerLongitude: Double, latitudeDelta: Double, longitudeDelta: Double)

    var region: MKCoordinateRegion {
        switch self {
        case .neighborhood:
            return .init()
        case .vendor(let lat, let lon, let span):
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
        case .route(let lat, let lon, let span), .search(let lat, let lon, let span):
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
        case .custom(let lat, let lon, let latDelta, let lonDelta):
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
}

// MARK: - Query Scope

struct GeoQueryScope: Equatable {
    var cityId: String
    var neighborhoodId: String
    var center: CLLocationCoordinate2D
    var radiusMeters: Double
    var categoryRawValues: [String]
    var availability: GeoAvailabilityFilter

    enum GeoAvailabilityFilter: String, Equatable {
        case any
        case liveOnly
        case expectedSoon
    }

    static func == (lhs: GeoQueryScope, rhs: GeoQueryScope) -> Bool {
        lhs.cityId == rhs.cityId
            && lhs.neighborhoodId == rhs.neighborhoodId
            && lhs.center.latitude == rhs.center.latitude
            && lhs.center.longitude == rhs.center.longitude
            && lhs.radiusMeters == rhs.radiusMeters
            && lhs.categoryRawValues == rhs.categoryRawValues
            && lhs.availability == rhs.availability
    }
}
