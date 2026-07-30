import Foundation

// MARK: - Language

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case tamil = "ta"

    var id: String { rawValue }

    var localeIdentifier: String { rawValue }

    var selectionKey: String {
        switch self {
        case .english: return "language.english"
        case .tamil: return "language.tamil"
        }
    }

    var profileLabelKey: String {
        switch self {
        case .english: return "language.english.short"
        case .tamil: return "language.tamil.short"
        }
    }
}

// MARK: - Flow & Onboarding

enum VendorFlowStep: Equatable {
    case splash
    case login
    case language
    case welcome
    case vendorName
    case businessCategory
    case workingHours
    case main
}

struct VendorOnboardingState: Equatable, Codable {
    var hasCompletedOnboarding: Bool = false
    var vendorName: String = ""
    var category: VendorCategory = .vegetables
    var workingHours: VendorWorkingHours = .defaultHours
    var area: ChennaiArea = .tNagar
}

// MARK: - Chennai Pilot Mock Data

/// Pure geography data — nonisolated so MapKit/geocoding actors can use it off the main actor.
nonisolated enum ChennaiArea: String, CaseIterable, Identifiable, Codable {
    case tNagar
    case westMambalam
    case thiruvanmiyur
    case adyar
    case velachery
    case besantNagar
    case annaNagar
    case ecr
    case kodambakkam

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .tNagar: return "area.t_nagar"
        case .westMambalam: return "area.west_mambalam"
        case .thiruvanmiyur: return "area.thiruvanmiyur"
        case .adyar: return "area.adyar"
        case .velachery: return "area.velachery"
        case .besantNagar: return "area.besant_nagar"
        case .annaNagar: return "area.anna_nagar"
        case .ecr: return "area.ecr"
        case .kodambakkam: return "area.kodambakkam"
        }
    }

    /// English source of truth — never expose `labelKey` when catalog is incomplete.
    var englishName: String {
        switch self {
        case .tNagar: return "T. Nagar"
        case .westMambalam: return "West Mambalam"
        case .thiruvanmiyur: return "Thiruvanmiyur"
        case .adyar: return "Adyar"
        case .velachery: return "Velachery"
        case .besantNagar: return "Besant Nagar"
        case .annaNagar: return "Anna Nagar"
        case .ecr: return "ECR"
        case .kodambakkam: return "Kodambakkam"
        }
    }

    var localizedName: String {
        LocalizedText.resolve(labelKey, fallback: englishName)
    }

    var landmarkEnglishName: String {
        switch self {
        case .tNagar: return "Pondy Bazaar"
        case .westMambalam: return "Mambalam Railway"
        case .thiruvanmiyur: return "Thiruvanmiyur MRTS"
        case .adyar: return "Adyar Bridge"
        case .velachery: return "Velachery Metro"
        case .besantNagar: return "Elliot's Beach"
        case .annaNagar: return "Anna Nagar Tower"
        case .ecr: return "ECR Junction"
        case .kodambakkam: return "Kodambakkam Market"
        }
    }

    var localizedLandmark: String {
        LocalizedText.resolve(landmarkKey, fallback: landmarkEnglishName)
    }

    var landmarkKey: String {
        switch self {
        case .tNagar: return "landmark.pondy_bazaar"
        case .westMambalam: return "landmark.mambalam_railway"
        case .thiruvanmiyur: return "landmark.thiruvanmiyur_mrts"
        case .adyar: return "landmark.adyar_bridge"
        case .velachery: return "landmark.velachery_metro"
        case .besantNagar: return "landmark.besant_nagar_beach"
        case .annaNagar: return "landmark.anna_nagar_tower"
        case .ecr: return "landmark.ecr_junction"
        case .kodambakkam: return "landmark.kodambakkam_market"
        }
    }

    /// Query sent to MapKit geocoding — real Chennai neighborhoods.
    var geocodeQuery: String {
        switch self {
        case .tNagar: return "T Nagar, Chennai, Tamil Nadu, India"
        case .westMambalam: return "West Mambalam, Chennai, Tamil Nadu, India"
        case .thiruvanmiyur: return "Thiruvanmiyur, Chennai, Tamil Nadu, India"
        case .adyar: return "Adyar, Chennai, Tamil Nadu, India"
        case .velachery: return "Velachery, Chennai, Tamil Nadu, India"
        case .besantNagar: return "Besant Nagar, Chennai, Tamil Nadu, India"
        case .annaNagar: return "Anna Nagar, Chennai, Tamil Nadu, India"
        case .ecr: return "East Coast Road, Chennai, Tamil Nadu, India"
        case .kodambakkam: return "Kodambakkam, Chennai, Tamil Nadu, India"
        }
    }

    var firebaseID: String {
        switch self {
        case .tNagar: return "t_nagar"
        case .westMambalam: return "west_mambalam"
        case .thiruvanmiyur: return "thiruvanmiyur"
        case .adyar: return "adyar"
        case .velachery: return "velachery"
        case .besantNagar: return "besant_nagar"
        case .annaNagar: return "anna_nagar"
        case .ecr: return "ecr"
        case .kodambakkam: return "kodambakkam"
        }
    }

    static func fromFirebaseID(_ id: String) -> ChennaiArea {
        switch id {
        case "t_nagar": return .tNagar
        case "west_mambalam": return .westMambalam
        case "thiruvanmiyur": return .thiruvanmiyur
        case "adyar": return .adyar
        case "velachery": return .velachery
        case "besant_nagar": return .besantNagar
        case "anna_nagar": return .annaNagar
        case "ecr": return .ecr
        case "kodambakkam": return .kodambakkam
        default: return .tNagar
        }
    }

    /// Seed coordinate used only until geocoding resolves.
    var seedCoordinate: CodableCoordinate {
        switch self {
        case .tNagar: return CodableCoordinate(latitude: 13.0418, longitude: 80.2341)
        case .westMambalam: return CodableCoordinate(latitude: 13.0382, longitude: 80.2219)
        case .thiruvanmiyur: return CodableCoordinate(latitude: 12.9850, longitude: 80.2590)
        case .adyar: return CodableCoordinate(latitude: 13.0067, longitude: 80.2576)
        case .velachery: return CodableCoordinate(latitude: 12.9750, longitude: 80.2207)
        case .besantNagar: return CodableCoordinate(latitude: 13.0001, longitude: 80.2668)
        case .annaNagar: return CodableCoordinate(latitude: 13.0850, longitude: 80.2101)
        case .ecr: return CodableCoordinate(latitude: 12.9141, longitude: 80.2512)
        case .kodambakkam: return CodableCoordinate(latitude: 13.0519, longitude: 80.2240)
        }
    }

    /// Map stays inside one neighbourhood patch.
    var neighborhoodMapSpan: Double { 0.008 }

    /// Close street-level zoom.
    var streetMapSpan: Double { 0.003 }
}

enum ChennaiLandmark: String, CaseIterable {
    case pondyBazaar
    case mambalamRailway
    case thiruvanmiyurMRTS
    case kapaleeshwararTemple
    case besantNagarBeach

    var labelKey: String {
        switch self {
        case .pondyBazaar: return "landmark.pondy_bazaar"
        case .mambalamRailway: return "landmark.mambalam_railway"
        case .thiruvanmiyurMRTS: return "landmark.thiruvanmiyur_mrts"
        case .kapaleeshwararTemple: return "landmark.kapaleeshwarar_temple"
        case .besantNagarBeach: return "landmark.besant_nagar_beach"
        }
    }
}

// MARK: - Business

enum VendorCategory: String, CaseIterable, Identifiable, Codable {
    case vegetables
    case fruits
    case flowers
    case milk
    case fish
    case bakery

    var id: String { rawValue }

    var titleKey: String { "category.\(rawValue)" }

    var systemImage: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .fruits: return "carrot.fill"
        case .flowers: return "camera.macro"
        case .milk: return "cup.and.saucer.fill"
        case .fish: return "fish.fill"
        case .bakery: return "birthday.cake.fill"
        }
    }

    var tintName: String {
        switch self {
        case .vegetables, .fish: return "primary"
        case .fruits, .bakery: return "accent"
        case .flowers, .milk: return "info"
        }
    }
}

struct VendorWorkingHours: Equatable, Codable {
    var startMinutes: Int
    var endMinutes: Int

    static let defaultHours = VendorWorkingHours(startMinutes: 6 * 60, endMinutes: 20 * 60)

    func formatted(using formatter: DateFormatter) -> String {
        let start = minutesToDate(startMinutes)
        let end = minutesToDate(endMinutes)
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    private func minutesToDate(_ minutes: Int) -> Date {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Live & Summary

enum VendorLiveStatus: Equatable {
    case offline
    case live
}

struct VendorDaySummary: Equatable {
    var salesRupees: Int
    var customers: Int
    var hours: Double
}

struct VendorProfile: Equatable {
    var name: String
    var languageKey: String
    var phone: String
    var categoryKey: String
    var workingHours: String
    var areaKey: String
    var photoLocalPath: String?
}

enum VendorTab: Hashable, CaseIterable {
    case home
    case inventory
    case earnings
    case profile

    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .inventory: return "tab.inventory"
        case .earnings: return "tab.business"
        case .profile: return "tab.profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "map.fill"
        case .inventory: return "basket.fill"
        case .earnings: return "chart.bar.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Inventory & Earnings

enum VendorOfferingKind: String, Codable, CaseIterable, Identifiable {
    case product
    case service

    var id: String { rawValue }

    var title: String {
        switch self {
        case .product: return "Product"
        case .service: return "Service"
        }
    }
}

struct VendorInventoryItem: Identifiable, Equatable {
    let id: String
    let nameKey: String
    let displayName: String
    let priceRupees: Int
    let unitKey: String
    let unitLabel: String
    var kind: VendorOfferingKind
    var inStock: Bool
    var availableToday: Bool
    var stockQuantity: Int?
    var serviceDurationMinutes: Int?
    var category: String
}

struct VendorEarningsEntry: Identifiable, Equatable {
    let id: String
    let descriptionKey: String
    let amountRupees: Int
    let timeLabel: String
    var offeringId: String?
}

enum VendorMockData {
    static let defaultVendorName = "vendor.name.murugan"
    static let defaultPhone = "+91 98405 12345"
    static let defaultArea: ChennaiArea = .tNagar

    static let inventory: [VendorInventoryItem] = [
        .init(id: "tomato", nameKey: "inventory.item.tomato", displayName: "Tomatoes", priceRupees: 40, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 40, serviceDurationMinutes: nil, category: "vegetables"),
        .init(id: "onion", nameKey: "inventory.item.onion", displayName: "Onions", priceRupees: 35, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 25, serviceDurationMinutes: nil, category: "vegetables"),
        .init(id: "potato", nameKey: "inventory.item.potato", displayName: "Potatoes", priceRupees: 30, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: false, availableToday: false, stockQuantity: 0, serviceDurationMinutes: nil, category: "vegetables"),
        .init(id: "spinach", nameKey: "inventory.item.spinach", displayName: "Spinach", priceRupees: 20, unitKey: "inventory.unit.bunch", unitLabel: "bunch", kind: .product, inStock: true, availableToday: true, stockQuantity: 18, serviceDurationMinutes: nil, category: "vegetables"),
        .init(id: "banana", nameKey: "inventory.item.banana", displayName: "Bananas", priceRupees: 60, unitKey: "inventory.unit.dozen", unitLabel: "dozen", kind: .product, inStock: true, availableToday: true, stockQuantity: 12, serviceDurationMinutes: nil, category: "fruits"),
        .init(id: "coconut", nameKey: "inventory.item.coconut", displayName: "Coconut", priceRupees: 35, unitKey: "inventory.unit.each", unitLabel: "each", kind: .product, inStock: true, availableToday: true, stockQuantity: 30, serviceDurationMinutes: nil, category: "fruits"),
        .init(id: "ironing_shirt", nameKey: "inventory.item.ironing_shirt", displayName: "T-Shirt Ironing", priceRupees: 20, unitKey: "inventory.unit.each", unitLabel: "each", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 5, category: "ironing"),
        .init(id: "laundry_pickup", nameKey: "inventory.item.laundry_pickup", displayName: "Laundry Pickup", priceRupees: 200, unitKey: "inventory.unit.each", unitLabel: "bag", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 30, category: "laundry")
    ]

    static let earningsEntries: [VendorEarningsEntry] = [
        .init(id: "e1", descriptionKey: "earnings.entry.vegetables", amountRupees: 320, timeLabel: "9:15 AM", offeringId: "tomato"),
        .init(id: "e2", descriptionKey: "earnings.entry.fruits", amountRupees: 180, timeLabel: "11:40 AM", offeringId: "banana"),
        .init(id: "e3", descriptionKey: "earnings.entry.milk", amountRupees: 95, timeLabel: "1:05 PM", offeringId: nil),
        .init(id: "e4", descriptionKey: "earnings.entry.flowers", amountRupees: 210, timeLabel: "4:30 PM", offeringId: nil)
    ]

    static let todaySummary = VendorDaySummary(salesRupees: 805, customers: 18, hours: 5.5)
    static let emptyDaySummary = VendorDaySummary(salesRupees: 0, customers: 0, hours: 0.0)

    static func locationLabel(for area: ChennaiArea) -> String {
        "\(area.localizedName) · \(area.localizedLandmark)"
    }
}
