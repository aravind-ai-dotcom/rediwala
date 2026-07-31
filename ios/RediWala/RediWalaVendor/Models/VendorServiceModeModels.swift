import CoreLocation
import Foundation

enum VendorServiceMode: String, CaseIterable, Codable, Identifiable {
    case mobile
    case stationary
    case scheduled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mobile: return "Mobile"
        case .stationary: return "Stationary"
        case .scheduled: return "Scheduled Route"
        }
    }

    var tamilTitle: String {
        switch self {
        case .mobile: return "நடமாடும் சேவை"
        case .stationary: return "நிலையான சேவை"
        case .scheduled: return "அட்டவணை சேவை"
        }
    }

    var icon: String {
        switch self {
        case .mobile: return "car.fill"
        case .stationary: return "mappin.and.ellipse"
        case .scheduled: return "calendar.badge.clock"
        }
    }

    /// How often stationary / scheduled vendors must confirm presence.
    var presenceCheckIntervalMinutes: Int {
        switch self {
        case .mobile: return 120
        case .stationary: return 60
        case .scheduled: return 90
        }
    }

    var requiresPresenceConfirmation: Bool {
        self != .mobile
    }

    /// Mobile and scheduled vendors plan stops; stationary vendors stay put.
    var requiresRoute: Bool {
        self != .stationary
    }

    var prepRouteTitle: String {
        switch self {
        case .mobile: return "Today's Route"
        case .stationary: return "Location"
        case .scheduled: return "Today's Schedule"
        }
    }

    var prepRouteIcon: String {
        switch self {
        case .mobile: return "map.fill"
        case .stationary: return "mappin.circle.fill"
        case .scheduled: return "calendar"
        }
    }
}

enum VendorLiveSessionState: Equatable {
    case offline
    case preparing
    case live
    case stopping
    case failed(message: String)

    var isInteractive: Bool {
        switch self {
        case .offline, .live, .failed: return true
        case .preparing, .stopping: return false
        }
    }
}

enum DemandSignalType: String, Codable, CaseIterable, Hashable {
    case favoriteNearby
    case categoryInterest
    case visitRequest
    case recentDemand

    var title: String {
        switch self {
        case .favoriteNearby: return "Favorite vendor nearby"
        case .categoryInterest: return "Category interest"
        case .visitRequest: return "Visit request"
        case .recentDemand: return "Recent demand"
        }
    }

    var colorName: String {
        switch self {
        case .favoriteNearby: return "accent"
        case .categoryInterest: return "primary"
        case .visitRequest: return "info"
        case .recentDemand: return "danger"
        }
    }
}

struct VendorDemandSignal: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var subtitle: String
    var neighborhood: ChennaiArea
    var coordinate: CodableCoordinate
    var customerCount: Int
    var signalType: DemandSignalType
    var preferredTimeWindow: String?
    var category: VendorCategory
}

struct VendorRouteStopPlan: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var neighborhood: ChennaiArea
    var landmark: String
    var coordinate: CodableCoordinate
    var arrivalTime: Date
    var departureTime: Date
    var isCompleted: Bool
    var isCurrent: Bool
    var estimatedInterest: Int
    var notes: String?
    var source: String?
}

struct VendorAnnouncementDraft: Codable, Equatable, Identifiable {
    let id: String
    var vendorId: String
    var liveSessionId: String?
    var localFilePath: String?
    var storagePath: String?
    var durationSeconds: Int
    var recordedAt: Date
    var language: String
    var transcriptPlaceholder: String
    var isActive: Bool
    var activeWhileLive: Bool
    var customerPlaybackEnabled: Bool
    var vendorBroadcastEnabled: Bool
    var playbackIntervalMinutes: Int?
}

struct VendorLiveSession: Equatable, Codable, Identifiable {
    let id: String
    var vendorId: String
    var status: String
    var serviceMode: VendorServiceMode
    var startedAt: Date
    var announcementEnabled: Bool
    var locationBehavior: String
    var plannedStops: [VendorRouteStopPlan]
    var operatingHours: String
}

nonisolated struct CodableCoordinate: Codable, Equatable, Hashable {
    var latitude: Double
    var longitude: Double

    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum VendorServiceModeDemoData {
    /// Place names geocoded on first load via `VendorGeocodingService`.
    /// All stops stay inside the vendor's chosen neighbourhood — never mix distant areas.
    static func defaultStopTitles(for area: ChennaiArea) -> [(title: String, landmark: String, area: ChennaiArea)] {
        switch area {
        case .westMambalam:
            return [
                ("Postal Colony", "Postal Colony", area),
                ("Lake View Road", "Lake View Road", area),
                ("Arya Gowda Road", "Arya Gowda Road", area),
                ("Station Road", "Station Road", area),
                ("Temple Street", "Temple Street", area)
            ]
        case .thiruvanmiyur:
            return [
                ("RTO Office", "RTO Office", area),
                ("Kannappa Nagar", "Kannappa Nagar", area),
                ("Kottivakkam Beach Road", "Kottivakkam", area),
                ("Injambakkam Junction", "Injambakkam", area),
                ("Thiruvanmiyur Temple", "Temple", area)
            ]
        case .tNagar:
            return [
                ("Pondy Bazaar", "Pondy Bazaar", area),
                ("Usman Road", "Usman Road", area),
                ("North Usman Road", "North Usman Road", area),
                ("Panagal Park", "Panagal Park", area),
                ("Ranganathan Street", "Ranganathan Street", area)
            ]
        case .adyar:
            return [
                ("Adyar Bridge", "Adyar Bridge", area),
                ("LB Road", "LB Road", area),
                ("Gandhi Nagar", "Gandhi Nagar", area),
                ("Indira Nagar", "Indira Nagar", area),
                ("Adyar Depot", "Adyar Depot", area)
            ]
        case .besantNagar:
            return [
                ("Elliot's Beach", "Elliot's Beach", area),
                ("Kalakshetra Road", "Kalakshetra Road", area),
                ("4th Main Road", "4th Main Road", area),
                ("Ashtalakshmi Temple", "Temple", area),
                ("Besant Avenue", "Besant Avenue", area)
            ]
        case .velachery:
            return [
                ("Velachery Market", "Market", area),
                ("Vijayanagar Bus Stand", "Bus Stand", area),
                ("Taramani Link Road", "Taramani Link", area),
                ("Velachery MRTS", "MRTS", area),
                ("100 Feet Road", "100 Feet Road", area)
            ]
        case .annaNagar:
            return [
                ("Anna Nagar Tower", "Tower", area),
                ("2nd Avenue", "2nd Avenue", area),
                ("Shanthi Colony", "Shanthi Colony", area),
                ("Thirumangalam", "Thirumangalam", area),
                ("Anna Nagar East", "East", area)
            ]
        case .kodambakkam:
            return [
                ("Kodambakkam Market", "Market", area),
                ("Power House", "Power House", area),
                ("Ashok Nagar Metro", "Ashok Nagar", area),
                ("Trustpuram", "Trustpuram", area),
                ("Vadapalani Signal", "Vadapalani", area)
            ]
        case .ecr:
            return [
                ("ECR Junction", "Junction", area),
                ("Sholinganallur", "Sholinganallur", area),
                ("Neelankarai", "Neelankarai", area),
                ("Palavakkam", "Palavakkam", area),
                ("Uthandi", "Uthandi", area)
            ]
        }
    }

    static func defaultStops(for area: ChennaiArea) -> [VendorRouteStopPlan] {
        let now = Date()
        func plus(_ minutes: Int) -> Date {
            Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now
        }
        let templates = defaultStopTitles(for: area)
        // Circuit waypoints around the neighborhood center — unique map positions.
        var stops = templates.enumerated().map { index, item in
            VendorRouteStopPlan(
                id: "stop_\(index + 1)",
                title: item.title,
                neighborhood: item.area,
                landmark: item.landmark,
                coordinate: circuitCoordinate(for: area, index: index, total: templates.count),
                arrivalTime: plus(12 + index * 28),
                departureTime: plus(22 + index * 28),
                isCompleted: false,
                isCurrent: index == 0,
                estimatedInterest: max(2, 6 - index),
                notes: nil,
                source: "default"
            )
        }
        // Close the loop: end where you started.
        if let first = stops.first {
            let returnIndex = stops.count
            stops.append(
                VendorRouteStopPlan(
                    id: "stop_return",
                    title: "Return · \(first.title)",
                    neighborhood: first.neighborhood,
                    landmark: first.landmark,
                    coordinate: first.coordinate,
                    arrivalTime: plus(12 + returnIndex * 28),
                    departureTime: plus(22 + returnIndex * 28),
                    isCompleted: false,
                    isCurrent: false,
                    estimatedInterest: first.estimatedInterest,
                    notes: "Loop complete — back to start",
                    source: "circuit_return"
                )
            )
        }
        return stops
    }

    /// Spread waypoints in a neighborhood circuit so the map shows a real path.
    static func circuitCoordinate(for area: ChennaiArea, index: Int, total: Int) -> CodableCoordinate {
        let center = area.seedCoordinate
        let count = max(total, 1)
        let angle = (2 * Double.pi * Double(index) / Double(count)) - (.pi / 2)
        let latRadius = 0.0038
        let lngRadius = 0.0042
        return CodableCoordinate(
            latitude: center.latitude + latRadius * cos(angle),
            longitude: center.longitude + lngRadius * sin(angle)
        )
    }

    /// Customer interest spots near today's circuit — always inside the operating area.
    static func demoDemandClusters(for area: ChennaiArea, category: VendorCategory) -> [DemandCluster] {
        let center = area.seedCoordinate
        let productHint: String
        switch category {
        case .vegetables: productHint = "Tomatoes · Onions"
        case .fruits: productHint = "Bananas · Coconut"
        case .flowers, .templeFlowers: productHint = "Jasmine · Garlands"
        case .ironing: productHint = "Shirts · Bedsheets"
        case .laundry: productHint = "Pickup bag"
        case .milk: productHint = "Morning delivery"
        case .foodTruck: productHint = "Lunch special"
        case .cable: productHint = "Monthly collection"
        case .tailor: productHint = "Alterations"
        case .fish: productHint = "Fresh catch"
        case .bakery: productHint = "Bread · Snacks"
        }

        let offsets: [(Double, Double, Int, String)] = [
            (0.0018, 0.0022, 5, "Alley near \(area.landmarkEnglishName)"),
            (-0.0021, 0.0014, 3, "Apartment lane"),
            (0.0006, -0.0026, 4, "Side street waiting"),
            (-0.0015, -0.0018, 2, "Gate request")
        ]

        return offsets.enumerated().map { index, item in
            DemandCluster(
                id: "demo_\(area.firebaseID)_\(index)",
                neighborhoodId: area.firebaseID,
                neighborhoodName: area.englishName,
                coordinate: CodableCoordinate(
                    latitude: center.latitude + item.0,
                    longitude: center.longitude + item.1
                ),
                customerCount: item.2,
                level: DemandLevel.from(customerCount: item.2),
                categories: [category.rawValue],
                productHints: [productHint, item.3],
                preferredTimeWindow: index == 0 ? "Now – 30 min" : nil,
                signalTypes: [.categoryInterest, .visitRequest]
            )
        }
    }

    static var demandSignals: [VendorDemandSignal] {
        demoDemandClusters(for: .tNagar, category: .vegetables).map { cluster in
            VendorDemandSignal(
                id: cluster.id,
                title: "\(cluster.customerCount) customers nearby",
                subtitle: cluster.productHints.joined(separator: " · "),
                neighborhood: .tNagar,
                coordinate: cluster.coordinate,
                customerCount: cluster.customerCount,
                signalType: cluster.signalTypes.first ?? .categoryInterest,
                preferredTimeWindow: cluster.preferredTimeWindow,
                category: .vegetables
            )
        }
    }
}
