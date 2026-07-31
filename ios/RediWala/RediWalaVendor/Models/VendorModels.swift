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
    case foodTruck
    case ironing
    case laundry
    case cable
    case templeFlowers
    case tailor

    var id: String { rawValue }

    var titleKey: String { "category.\(rawValue)" }

    var englishTitle: String {
        switch self {
        case .vegetables: return "Vegetables"
        case .fruits: return "Fruits"
        case .flowers: return "Flowers"
        case .milk: return "Milk Delivery"
        case .fish: return "Fish"
        case .bakery: return "Bakery"
        case .foodTruck: return "Food Truck"
        case .ironing: return "Ironing"
        case .laundry: return "Laundry"
        case .cable: return "Cable Collection"
        case .templeFlowers: return "Temple Flowers"
        case .tailor: return "Tailor"
        }
    }

    /// Business-specific label for today's catalog.
    var offeringsTitle: String {
        switch self {
        case .vegetables, .fruits, .fish, .bakery: return "Products"
        case .flowers, .templeFlowers: return "Flowers"
        case .foodTruck: return "Menu"
        case .ironing, .laundry, .tailor: return "Services"
        case .cable: return "Collections"
        case .milk: return "Today's Delivery"
        }
    }

    var systemImage: String {
        switch self {
        case .vegetables: return "basket.fill"
        case .fruits: return "carrot.fill"
        case .flowers: return "leaf.fill"
        case .templeFlowers: return "camera.macro"
        case .milk: return "waterbottle.fill"
        case .fish: return "fish.fill"
        case .bakery: return "birthday.cake.fill"
        case .foodTruck: return "box.truck.fill"
        case .ironing: return "tshirt.fill"
        case .laundry: return "washer.fill"
        case .cable: return "tv.fill"
        case .tailor: return "scissors"
        }
    }

    var tintName: String {
        switch self {
        case .vegetables, .fish, .laundry: return "primary"
        case .fruits, .bakery, .foodTruck, .ironing: return "accent"
        case .flowers, .milk, .templeFlowers, .cable, .tailor: return "info"
        }
    }

    /// Sensible default working mode for this business type.
    var defaultServiceMode: VendorServiceMode {
        switch self {
        case .foodTruck, .ironing, .tailor, .bakery:
            return .stationary
        case .milk, .laundry, .cable:
            return .scheduled
        case .vegetables, .fruits, .flowers, .fish, .templeFlowers:
            return .mobile
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
    case map
    case messages
    case earnings
    case profile

    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .map: return "tab.map"
        case .messages: return "tab.messages"
        case .earnings: return "tab.business"
        case .profile: return "tab.profile"
        }
    }

    var englishTitle: String {
        switch self {
        case .home: return "Home"
        case .map: return "Map"
        case .messages: return "Messages"
        case .earnings: return "Business"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .map: return "map.fill"
        case .messages: return "bubble.left.and.bubble.right.fill"
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

struct VendorInventoryItem: Identifiable, Equatable, Codable {
    let id: String
    let nameKey: String
    var displayName: String
    var priceRupees: Int
    let unitKey: String
    var unitLabel: String
    var kind: VendorOfferingKind
    var inStock: Bool
    var availableToday: Bool
    var stockQuantity: Int?
    var serviceDurationMinutes: Int?
    var category: String
    var notes: String?

    var rateCardLabel: String {
        "₹\(priceRupees)/\(unitLabel)"
    }
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
        // Vegetables
        .init(id: "tomato", nameKey: "inventory.item.tomato", displayName: "Tomatoes", priceRupees: 35, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 40, serviceDurationMinutes: nil, category: "vegetables", notes: "Fresh morning stock"),
        .init(id: "onion", nameKey: "inventory.item.onion", displayName: "Onions", priceRupees: 40, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 25, serviceDurationMinutes: nil, category: "vegetables", notes: nil),
        .init(id: "potato", nameKey: "inventory.item.potato", displayName: "Potatoes", priceRupees: 45, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 30, serviceDurationMinutes: nil, category: "vegetables", notes: nil),
        .init(id: "spinach", nameKey: "inventory.item.spinach", displayName: "Spinach", priceRupees: 20, unitKey: "inventory.unit.bunch", unitLabel: "bunch", kind: .product, inStock: true, availableToday: true, stockQuantity: 18, serviceDurationMinutes: nil, category: "vegetables", notes: nil),
        .init(id: "carrot", nameKey: "inventory.item.carrot", displayName: "Carrots", priceRupees: 50, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 15, serviceDurationMinutes: nil, category: "vegetables", notes: nil),
        // Fruits
        .init(id: "banana", nameKey: "inventory.item.banana", displayName: "Bananas", priceRupees: 60, unitKey: "inventory.unit.dozen", unitLabel: "dozen", kind: .product, inStock: true, availableToday: true, stockQuantity: 12, serviceDurationMinutes: nil, category: "fruits", notes: nil),
        .init(id: "coconut", nameKey: "inventory.item.coconut", displayName: "Coconut", priceRupees: 35, unitKey: "inventory.unit.each", unitLabel: "each", kind: .product, inStock: true, availableToday: true, stockQuantity: 30, serviceDurationMinutes: nil, category: "fruits", notes: nil),
        .init(id: "mango", nameKey: "inventory.item.mango", displayName: "Mangoes", priceRupees: 120, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 10, serviceDurationMinutes: nil, category: "fruits", notes: "Seasonal"),
        // Flowers / Temple
        .init(id: "jasmine", nameKey: "inventory.item.jasmine", displayName: "Jasmine", priceRupees: 30, unitKey: "inventory.unit.string", unitLabel: "string", kind: .product, inStock: true, availableToday: true, stockQuantity: 40, serviceDurationMinutes: nil, category: "flowers", notes: "Temple fresh"),
        .init(id: "rose", nameKey: "inventory.item.rose", displayName: "Roses", priceRupees: 50, unitKey: "inventory.unit.bunch", unitLabel: "bunch", kind: .product, inStock: true, availableToday: true, stockQuantity: 20, serviceDurationMinutes: nil, category: "flowers", notes: nil),
        .init(id: "garland", nameKey: "inventory.item.garland", displayName: "Temple Garland", priceRupees: 80, unitKey: "inventory.unit.each", unitLabel: "each", kind: .product, inStock: true, availableToday: true, stockQuantity: 15, serviceDurationMinutes: nil, category: "templeFlowers", notes: nil),
        .init(id: "lotus", nameKey: "inventory.item.lotus", displayName: "Lotus", priceRupees: 40, unitKey: "inventory.unit.each", unitLabel: "each", kind: .product, inStock: true, availableToday: true, stockQuantity: 12, serviceDurationMinutes: nil, category: "templeFlowers", notes: nil),
        // Ironing
        .init(id: "ironing_shirt", nameKey: "inventory.item.ironing_shirt", displayName: "T-Shirt", priceRupees: 20, unitKey: "inventory.unit.each", unitLabel: "each", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 5, category: "ironing", notes: nil),
        .init(id: "ironing_bedsheet", nameKey: "inventory.item.ironing_bedsheet", displayName: "Bedsheet", priceRupees: 80, unitKey: "inventory.unit.each", unitLabel: "each", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 15, category: "ironing", notes: nil),
        .init(id: "ironing_pant", nameKey: "inventory.item.ironing_pant", displayName: "Pants", priceRupees: 25, unitKey: "inventory.unit.each", unitLabel: "each", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 8, category: "ironing", notes: nil),
        // Laundry
        .init(id: "laundry_pickup", nameKey: "inventory.item.laundry_pickup", displayName: "Laundry Pickup", priceRupees: 200, unitKey: "inventory.unit.each", unitLabel: "bag", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 30, category: "laundry", notes: "Same-day return"),
        .init(id: "laundry_wash", nameKey: "inventory.item.laundry_wash", displayName: "Wash & Fold", priceRupees: 150, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 60, category: "laundry", notes: nil),
        // Milk
        .init(id: "milk_packet", nameKey: "inventory.item.milk", displayName: "Milk Packet", priceRupees: 30, unitKey: "inventory.unit.each", unitLabel: "packet", kind: .product, inStock: true, availableToday: true, stockQuantity: 50, serviceDurationMinutes: nil, category: "milk", notes: "Morning delivery"),
        .init(id: "curd", nameKey: "inventory.item.curd", displayName: "Curd", priceRupees: 40, unitKey: "inventory.unit.each", unitLabel: "cup", kind: .product, inStock: true, availableToday: true, stockQuantity: 20, serviceDurationMinutes: nil, category: "milk", notes: nil),
        // Food truck
        .init(id: "dosa", nameKey: "inventory.item.dosa", displayName: "Dosa", priceRupees: 60, unitKey: "inventory.unit.each", unitLabel: "plate", kind: .product, inStock: true, availableToday: true, stockQuantity: 40, serviceDurationMinutes: 10, category: "foodTruck", notes: nil),
        .init(id: "filter_coffee", nameKey: "inventory.item.coffee", displayName: "Filter Coffee", priceRupees: 25, unitKey: "inventory.unit.each", unitLabel: "cup", kind: .product, inStock: true, availableToday: true, stockQuantity: 60, serviceDurationMinutes: 5, category: "foodTruck", notes: nil),
        // Cable / Tailor / Fish / Bakery
        .init(id: "cable_monthly", nameKey: "inventory.item.cable", displayName: "Monthly Collection", priceRupees: 300, unitKey: "inventory.unit.each", unitLabel: "home", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 10, category: "cable", notes: nil),
        .init(id: "hem", nameKey: "inventory.item.hem", displayName: "Pant Hem", priceRupees: 80, unitKey: "inventory.unit.each", unitLabel: "pair", kind: .service, inStock: true, availableToday: true, stockQuantity: nil, serviceDurationMinutes: 20, category: "tailor", notes: nil),
        .init(id: "fish_seervai", nameKey: "inventory.item.fish", displayName: "Seer Fish", priceRupees: 450, unitKey: "inventory.unit.kg", unitLabel: "kg", kind: .product, inStock: true, availableToday: true, stockQuantity: 8, serviceDurationMinutes: nil, category: "fish", notes: "Morning catch"),
        .init(id: "bread", nameKey: "inventory.item.bread", displayName: "Bread", priceRupees: 40, unitKey: "inventory.unit.each", unitLabel: "loaf", kind: .product, inStock: true, availableToday: true, stockQuantity: 20, serviceDurationMinutes: nil, category: "bakery", notes: nil)
    ]

    static func offerings(for category: VendorCategory) -> [VendorInventoryItem] {
        let key = category.rawValue
        // Temple flowers share flower catalog when specific items are thin.
        let aliases: [String]
        switch category {
        case .templeFlowers: aliases = ["templeFlowers", "flowers"]
        case .flowers: aliases = ["flowers"]
        default: aliases = [key]
        }
        let filtered = inventory.filter { aliases.contains($0.category) }
        // Never fall back across unrelated businesses (no ironing for vegetable sellers).
        return filtered
    }

    static let earningsEntries: [VendorEarningsEntry] = [
        .init(id: "e1", descriptionKey: "Tomatoes · 4 kg", amountRupees: 140, timeLabel: "9:15 AM", offeringId: "tomato"),
        .init(id: "e2", descriptionKey: "Potatoes · 3 kg", amountRupees: 135, timeLabel: "11:40 AM", offeringId: "potato"),
        .init(id: "e3", descriptionKey: "Onions · 2 kg", amountRupees: 80, timeLabel: "1:05 PM", offeringId: "onion"),
        .init(id: "e4", descriptionKey: "Spinach · 3 bunches", amountRupees: 60, timeLabel: "4:30 PM", offeringId: "spinach")
    ]

    static func earningsEntries(for category: VendorCategory) -> [VendorEarningsEntry] {
        let ids = Set(offerings(for: category).map(\.id))
        let matched = earningsEntries.filter { entry in
            guard let offeringId = entry.offeringId else { return false }
            return ids.contains(offeringId)
        }
        if !matched.isEmpty { return matched }
        return offerings(for: category).prefix(3).enumerated().map { index, item in
            VendorEarningsEntry(
                id: "gen_\(item.id)",
                descriptionKey: "\(item.displayName) · sale",
                amountRupees: item.priceRupees * max(1, 2 - index),
                timeLabel: ["9:15 AM", "11:40 AM", "4:30 PM"][index % 3],
                offeringId: item.id
            )
        }
    }

    static let todaySummary = VendorDaySummary(salesRupees: 805, customers: 18, hours: 5.5)
    static let emptyDaySummary = VendorDaySummary(salesRupees: 0, customers: 0, hours: 0.0)

    static func locationLabel(for area: ChennaiArea) -> String {
        "\(area.localizedName) · \(area.localizedLandmark)"
    }
}
