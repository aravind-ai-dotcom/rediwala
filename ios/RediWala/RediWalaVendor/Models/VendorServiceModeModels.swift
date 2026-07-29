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
    /// All stops stay inside the vendor's chosen neighbourhood.
    static func defaultStopTitles(for area: ChennaiArea) -> [(title: String, landmark: String, area: ChennaiArea)] {
        [
            ("RTO Office", "RTO Office", area),
            ("Kurinji Apartment", "Kurinji Apartment", area),
            ("Postal Colony", "Postal Colony", area),
            ("Kannappan Colony", "Kannappan Colony", area),
            ("Pondy Bazaar", "Pondy Bazaar", area)
        ]
    }

    static func defaultStops(for area: ChennaiArea) -> [VendorRouteStopPlan] {
        let now = Date()
        func plus(_ minutes: Int) -> Date {
            Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now
        }
        let templates = defaultStopTitles(for: area)
        return templates.enumerated().map { index, item in
            VendorRouteStopPlan(
                id: "stop_\(index + 1)",
                title: item.title,
                neighborhood: item.area,
                landmark: item.landmark,
                coordinate: item.area.seedCoordinate,
                arrivalTime: plus(15 + index * 40),
                departureTime: plus(35 + index * 40),
                isCompleted: false,
                isCurrent: index == 0,
                estimatedInterest: max(2, 6 - index),
                notes: nil,
                source: "default"
            )
        }
    }

    static var demandSignals: [VendorDemandSignal] {
        [
            VendorDemandSignal(
                id: "demand_1",
                title: "5 interested customers near Postal Colony",
                subtitle: "High demand for vegetables",
                neighborhood: .tNagar,
                coordinate: CodableCoordinate(latitude: 13.0369, longitude: 80.2302),
                customerCount: 5,
                signalType: .categoryInterest,
                preferredTimeWindow: "2:00 PM - 3:00 PM",
                category: .vegetables
            ),
            VendorDemandSignal(
                id: "demand_2",
                title: "3 favorites nearby",
                subtitle: "Customers recently favorited your profile",
                neighborhood: .westMambalam,
                coordinate: CodableCoordinate(latitude: 13.0380, longitude: 80.2224),
                customerCount: 3,
                signalType: .favoriteNearby,
                preferredTimeWindow: nil,
                category: .vegetables
            ),
            VendorDemandSignal(
                id: "demand_3",
                title: "2 visit requests this morning",
                subtitle: "Near Thiruvanmiyur market lane",
                neighborhood: .thiruvanmiyur,
                coordinate: CodableCoordinate(latitude: 12.9859, longitude: 80.2585),
                customerCount: 2,
                signalType: .visitRequest,
                preferredTimeWindow: "4:30 PM - 5:30 PM",
                category: .vegetables
            )
        ]
    }
}
