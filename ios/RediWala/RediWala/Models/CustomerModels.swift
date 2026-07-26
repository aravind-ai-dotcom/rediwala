import CoreLocation
import Foundation

// MARK: - Language

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case tamil = "ta"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var localizationKey: String {
        switch self {
        case .english: return "language.english"
        case .tamil: return "language.tamil"
        }
    }
}

// MARK: - Pilot Neighborhoods

enum PilotNeighborhood: String, CaseIterable, Identifiable, Codable {
    case tNagar
    case westMambalam
    case thiruvanmiyur

    var id: String { rawValue }

    var nameKey: String { "neighborhood.\(rawValue)" }
    var tamilNameKey: String { "neighborhood.\(rawValue).ta_label" }

    /// Chennai pilot coordinates (WGS84).
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .tNagar:
            return CLLocationCoordinate2D(latitude: 13.0418, longitude: 80.2341)
        case .westMambalam:
            return CLLocationCoordinate2D(latitude: 13.0382, longitude: 80.2219)
        case .thiruvanmiyur:
            return CLLocationCoordinate2D(latitude: 12.9850, longitude: 80.2590)
        }
    }

    var spanDelta: Double { 0.018 }
}

// MARK: - Category Groups & Categories

enum CategoryGroup: String, CaseIterable, Identifiable, Codable {
    case freshDaily
    case neighborhoodServices
    case recyclingBuyers
    case streetTreats

    var id: String { rawValue }

    var titleKey: String { "categoryGroup.\(rawValue)" }

    var displayOrder: Int {
        switch self {
        case .freshDaily: return 0
        case .neighborhoodServices: return 1
        case .recyclingBuyers: return 2
        case .streetTreats: return 3
        }
    }

    var tint: CategoryTint {
        switch self {
        case .freshDaily: return .primary
        case .neighborhoodServices: return .info
        case .recyclingBuyers: return .accent
        case .streetTreats: return .accent
        }
    }
}

enum CategoryTint: String {
    case primary
    case accent
    case info
}

enum SellerCategory: String, CaseIterable, Identifiable, Codable {
    // Fresh & Daily
    case vegetables
    case fruits
    case flowers
    case milk
    case fish
    case bakery
    // Neighborhood Services
    case knifeSharpening
    case cobbler
    case tailor
    case sofaRepair
    // Recycling Buyers
    case oldNewspapers
    case plastic
    case cardboard
    case metalScrap
    // Street Treats
    case kulfi
    case roastedCorn
    case peanuts

    var id: String { rawValue }

    var localizationKey: String { "category.\(rawValue)" }
    var descriptionKey: String { "category.\(rawValue).description" }

    var parentGroup: CategoryGroup {
        switch self {
        case .vegetables, .fruits, .flowers, .milk, .fish, .bakery:
            return .freshDaily
        case .knifeSharpening, .cobbler, .tailor, .sofaRepair:
            return .neighborhoodServices
        case .oldNewspapers, .plastic, .cardboard, .metalScrap:
            return .recyclingBuyers
        case .kulfi, .roastedCorn, .peanuts:
            return .streetTreats
        }
    }

    var systemImage: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .fruits: return "carrot.fill"
        case .flowers: return "camera.macro"
        case .milk: return "cup.and.saucer.fill"
        case .fish: return "fish.fill"
        case .bakery: return "birthday.cake.fill"
        case .knifeSharpening: return "scissors"
        case .cobbler: return "hammer.fill"
        case .tailor: return "scissors"
        case .sofaRepair: return "sofa.fill"
        case .oldNewspapers: return "newspaper.fill"
        case .plastic: return "arrow.3.trianglepath"
        case .cardboard: return "shippingbox.fill"
        case .metalScrap: return "wrench.and.screwdriver.fill"
        case .kulfi: return "snowflake"
        case .roastedCorn: return "flame.fill"
        case .peanuts: return "circle.grid.3x3.fill"
        }
    }

    var displayOrder: Int {
        switch self {
        case .vegetables: return 0
        case .fruits: return 1
        case .flowers: return 2
        case .milk: return 3
        case .fish: return 4
        case .bakery: return 5
        case .knifeSharpening: return 6
        case .cobbler: return 7
        case .tailor: return 8
        case .sofaRepair: return 9
        case .oldNewspapers: return 10
        case .plastic: return 11
        case .cardboard: return 12
        case .metalScrap: return 13
        case .kulfi: return 14
        case .roastedCorn: return 15
        case .peanuts: return 16
        }
    }

    var isComingSoon: Bool {
        switch self {
        case .tailor, .sofaRepair: return true
        default: return false
        }
    }

    static var selectableCases: [SellerCategory] {
        allCases.filter { !$0.isComingSoon }
    }

    static func categories(in group: CategoryGroup) -> [SellerCategory] {
        allCases
            .filter { $0.parentGroup == group }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
}

/// Catalog entry used by home grids.
struct MarketCategory: Identifiable, Equatable {
    let id: String
    let category: SellerCategory

    var localizationKey: String { category.localizationKey }
    var descriptionKey: String { category.descriptionKey }
    var systemImage: String { category.systemImage }
    var isComingSoon: Bool { category.isComingSoon }
    var displayOrder: Int { category.displayOrder }
    var parentGroup: CategoryGroup { category.parentGroup }

    init(category: SellerCategory) {
        self.id = category.id
        self.category = category
    }
}

// MARK: - Route / My Day

enum RouteStopStatus: String, Codable, Equatable {
    case completed
    case current
    case upcoming
}

struct RouteStop: Identifiable, Equatable, Codable {
    let id: String
    let timeLabel: String
    let titleKey: String
    let neighborhood: PilotNeighborhood
    let landmarkKey: String
    let latitude: Double
    let longitude: Double
    let status: RouteStopStatus
}

// MARK: - Seller

struct Seller: Identifiable, Equatable {
    let id: String
    let name: String
    let businessName: String?
    let category: SellerCategory
    let profileImageAssetName: String?
    let neighborhood: PilotNeighborhood
    let landmarkKey: String
    let latitude: Double
    let longitude: Double
    let isLive: Bool
    let distanceMeters: Int
    let directionKey: String
    let rating: Double
    let languages: [AppLanguage]
    let hasAnnouncement: Bool
    let announcementDurationSeconds: Int
    let routeStops: [RouteStop]
    let workingHours: String
    let descriptionKey: String
    let phone: String
    /// Reserved for a future remote photo URL (Firebase Storage / CDN).
    var photoURL: String?

    var categoryGroup: CategoryGroup { category.parentGroup }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(distanceMeters) m"
        }
        let km = Double(distanceMeters) / 1000.0
        return String(format: "%.1f km", km)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var announcementDurationLabel: String {
        let minutes = announcementDurationSeconds / 60
        let seconds = announcementDurationSeconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "0:%02d", seconds)
    }
}

/// Backward-compatible alias used by older call sites during the sprint.
typealias NearbyVendor = Seller
typealias VendorCategory = SellerCategory

struct CustomerProfile: Equatable {
    let nameKey: String
    let phone: String
    let areaKey: String
    /// Reserved for a future remote photo URL.
    var photoURL: String?
}

enum CustomerMockData {
    static let currentLocationKey = "neighborhood.tNagar"
    static let currentLocationTamilKey = "neighborhood.tNagar.ta_label"

    static var categories: [MarketCategory] {
        SellerCategory.allCases
            .sorted { $0.displayOrder < $1.displayOrder }
            .map { MarketCategory(category: $0) }
    }

    static var vendors: [Seller] { SyntheticChennaiData.sellers }

    static func vendor(id: String) -> Seller? {
        SyntheticChennaiData.sellers.first { $0.id == id }
    }

    static func vendors(in category: SellerCategory) -> [Seller] {
        SyntheticChennaiData.sellers.filter { $0.category == category }
    }

    static let profile = CustomerProfile(
        nameKey: "profile.name",
        phone: "+91 98765 43210",
        areaKey: "profile.area",
        photoURL: nil
    )
}
