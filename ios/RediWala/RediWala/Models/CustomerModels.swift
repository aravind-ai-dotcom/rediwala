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
    case adyar
    case velachery
    case besantNagar
    case annaNagar
    case kodambakkam
    case ashokNagar
    case mylapore
    case triplicane
    case saidapet
    case ecr
    case omr

    var id: String { rawValue }

    var nameKey: String { "neighborhood.\(rawValue)" }
    var tamilNameKey: String { "neighborhood.\(rawValue).ta_label" }

    var displayName: String {
        switch self {
        case .tNagar: return "T. Nagar"
        case .westMambalam: return "West Mambalam"
        case .thiruvanmiyur: return "Thiruvanmiyur"
        case .adyar: return "Adyar"
        case .velachery: return "Velachery"
        case .besantNagar: return "Besant Nagar"
        case .annaNagar: return "Anna Nagar"
        case .kodambakkam: return "Kodambakkam"
        case .ashokNagar: return "Ashok Nagar"
        case .mylapore: return "Mylapore"
        case .triplicane: return "Triplicane"
        case .saidapet: return "Saidapet"
        case .ecr: return "ECR"
        case .omr: return "OMR"
        }
    }

    /// Real Chennai neighborhood centers (WGS84).
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .tNagar:
            return CLLocationCoordinate2D(latitude: 13.0418, longitude: 80.2341)
        case .westMambalam:
            return CLLocationCoordinate2D(latitude: 13.0382, longitude: 80.2219)
        case .thiruvanmiyur:
            return CLLocationCoordinate2D(latitude: 12.9850, longitude: 80.2590)
        case .adyar:
            return CLLocationCoordinate2D(latitude: 13.0067, longitude: 80.2576)
        case .velachery:
            return CLLocationCoordinate2D(latitude: 12.9750, longitude: 80.2207)
        case .besantNagar:
            return CLLocationCoordinate2D(latitude: 13.0001, longitude: 80.2668)
        case .annaNagar:
            return CLLocationCoordinate2D(latitude: 13.0850, longitude: 80.2101)
        case .kodambakkam:
            return CLLocationCoordinate2D(latitude: 13.0519, longitude: 80.2240)
        case .ashokNagar:
            return CLLocationCoordinate2D(latitude: 13.0335, longitude: 80.2120)
        case .mylapore:
            return CLLocationCoordinate2D(latitude: 13.0338, longitude: 80.2680)
        case .triplicane:
            return CLLocationCoordinate2D(latitude: 13.0580, longitude: 80.2750)
        case .saidapet:
            return CLLocationCoordinate2D(latitude: 13.0210, longitude: 80.2230)
        case .ecr:
            return CLLocationCoordinate2D(latitude: 12.9141, longitude: 80.2512)
        case .omr:
            return CLLocationCoordinate2D(latitude: 12.9100, longitude: 80.2270)
        }
    }

    var spanDelta: Double { 0.012 }

    var landmarkKey: String {
        switch self {
        case .tNagar: return "landmark.pondy_bazaar"
        case .westMambalam: return "landmark.mambalam_railway"
        case .thiruvanmiyur: return "landmark.thiruvanmiyur_mrts"
        case .adyar: return "landmark.adyar_bridge"
        case .velachery: return "landmark.velachery_metro"
        case .besantNagar: return "landmark.besant_nagar_beach"
        case .annaNagar: return "landmark.anna_nagar_tower"
        case .kodambakkam: return "landmark.kodambakkam_market"
        case .ashokNagar: return "landmark.ashok_nagar"
        case .mylapore: return "landmark.kapaleeshwarar_temple"
        case .triplicane: return "landmark.triplicane"
        case .saidapet: return "landmark.saidapet"
        case .ecr: return "landmark.ecr_junction"
        case .omr: return "landmark.omr"
        }
    }
}

// MARK: - Category Groups & Categories

enum CategoryGroup: String, CaseIterable, Identifiable, Codable {
    case freshDaily
    case neighborhoodServices
    case recyclingBuyers
    case streetTreats
    case homeDelivery

    var id: String { rawValue }

    var titleKey: String { "categoryGroup.\(rawValue)" }

    var displayOrder: Int {
        switch self {
        case .freshDaily: return 0
        case .neighborhoodServices: return 1
        case .homeDelivery: return 2
        case .recyclingBuyers: return 3
        case .streetTreats: return 4
        }
    }

    var tint: CategoryTint {
        switch self {
        case .freshDaily: return .primary
        case .neighborhoodServices: return .info
        case .homeDelivery: return .accent
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
    case ironing
    case laundry
    case cableBill
    case householdRepair
    case electricalRepair
    case mobileMechanic
    // Home Delivery
    case waterCan
    case gasCylinder
    case medicalDelivery
    // Recycling Buyers
    case oldNewspapers
    case plastic
    case cardboard
    case metalScrap
    // Street Treats
    case kulfi
    case roastedCorn
    case peanuts
    case foodTruck
    case iceCream
    case juices
    case tenderCoconut

    var id: String { rawValue }

    var localizationKey: String { "category.\(rawValue)" }
    var descriptionKey: String { "category.\(rawValue).description" }

    var parentGroup: CategoryGroup {
        switch self {
        case .vegetables, .fruits, .flowers, .milk, .fish, .bakery:
            return .freshDaily
        case .knifeSharpening, .cobbler, .tailor, .sofaRepair, .ironing, .laundry,
                .cableBill, .householdRepair, .electricalRepair, .mobileMechanic:
            return .neighborhoodServices
        case .waterCan, .gasCylinder, .medicalDelivery:
            return .homeDelivery
        case .oldNewspapers, .plastic, .cardboard, .metalScrap:
            return .recyclingBuyers
        case .kulfi, .roastedCorn, .peanuts, .foodTruck, .iceCream, .juices, .tenderCoconut:
            return .streetTreats
        }
    }

    var systemImage: String {
        switch self {
        case .vegetables: return "basket.fill"
        case .fruits: return "carrot.fill"
        case .flowers: return "leaf.fill"
        case .milk: return "waterbottle.fill"
        case .fish: return "fish.fill"
        case .bakery: return "birthday.cake.fill"
        case .knifeSharpening: return "diamond.fill"
        case .cobbler: return "hammer.fill"
        case .tailor: return "scissors"
        case .sofaRepair: return "sofa.fill"
        case .ironing: return "tshirt.fill"
        case .laundry: return "washer.fill"
        case .cableBill: return "tv.fill"
        case .householdRepair: return "wrench.and.screwdriver.fill"
        case .electricalRepair: return "bolt.fill"
        case .mobileMechanic: return "car.fill"
        case .waterCan: return "drop.fill"
        case .gasCylinder: return "flame.circle.fill"
        case .medicalDelivery: return "cross.case.fill"
        case .oldNewspapers: return "newspaper.fill"
        case .plastic: return "arrow.3.trianglepath"
        case .cardboard: return "shippingbox.fill"
        case .metalScrap: return "wrench.and.screwdriver.fill"
        case .kulfi: return "snowflake"
        case .roastedCorn: return "flame.fill"
        case .peanuts: return "circle.grid.3x3.fill"
        case .foodTruck: return "box.truck.fill"
        case .iceCream: return "snowflake"
        case .juices: return "cup.and.saucer.fill"
        case .tenderCoconut: return "circle.fill"
        }
    }

    var displayOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    var isComingSoon: Bool { false }

    var defaultServiceMode: CustomerServiceMode {
        switch self {
        case .foodTruck, .iceCream, .juices, .kulfi, .medicalDelivery:
            return .stationary
        case .cableBill, .laundry, .ironing, .waterCan, .gasCylinder, .milk:
            return .scheduled
        default:
            return .mobile
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
    /// Firebase Storage path for today's announcement audio, when available.
    var announcementStoragePath: String?
    let routeStops: [RouteStop]
    let workingHours: String
    let descriptionKey: String
    let phone: String
    /// Reserved for a future remote photo URL (Firebase Storage / CDN).
    var photoURL: String?
    /// How this vendor operates today.
    var serviceMode: CustomerServiceMode
    /// Human progress text, e.g. "Currently serving Block C".
    var progressLabel: String?
    /// Optional apartment / street context.
    var apartmentComplex: String?
    var streetName: String?
    /// Short preview of today's spoken message.
    var todaysMessagePreview: String?
    /// Estimated arrival text for the customer.
    var etaLabel: String?
    /// Server-side presence expiry. When past, treat as Offline even if `isLive` is true.
    var presenceExpiresAt: Date? = nil

    /// Live and not past presence expiry (prevents ghost vendors).
    var isEffectivelyLive: Bool {
        guard isLive else { return false }
        if let expires = presenceExpiresAt, expires < Date() { return false }
        return true
    }

    var categoryGroup: CategoryGroup { category.parentGroup }
    var behaviorProfile: ServiceBehaviorProfile {
        ServiceBehaviorProfile.profile(for: category, mode: serviceMode)
    }

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

    var displayBusinessName: String {
        businessName ?? name
    }

    func with(
        isLive: Bool? = nil,
        distanceMeters: Int? = nil,
        announcementStoragePath: String? = nil,
        photoURL: String? = nil,
        presenceExpiresAt: Date? = nil
    ) -> Seller {
        Seller(
            id: id,
            name: name,
            businessName: businessName,
            category: category,
            profileImageAssetName: profileImageAssetName,
            neighborhood: neighborhood,
            landmarkKey: landmarkKey,
            latitude: latitude,
            longitude: longitude,
            isLive: isLive ?? self.isLive,
            distanceMeters: distanceMeters ?? self.distanceMeters,
            directionKey: directionKey,
            rating: rating,
            languages: languages,
            hasAnnouncement: hasAnnouncement,
            announcementDurationSeconds: announcementDurationSeconds,
            announcementStoragePath: announcementStoragePath ?? self.announcementStoragePath,
            routeStops: routeStops,
            workingHours: workingHours,
            descriptionKey: descriptionKey,
            phone: phone,
            photoURL: photoURL ?? self.photoURL,
            serviceMode: serviceMode,
            progressLabel: progressLabel,
            apartmentComplex: apartmentComplex,
            streetName: streetName,
            todaysMessagePreview: todaysMessagePreview,
            etaLabel: etaLabel,
            presenceExpiresAt: presenceExpiresAt ?? self.presenceExpiresAt
        )
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
