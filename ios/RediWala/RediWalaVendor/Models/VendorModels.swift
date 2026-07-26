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

enum ChennaiArea: String, CaseIterable, Identifiable, Codable {
    case tNagar
    case westMambalam
    case thiruvanmiyur

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .tNagar: return "area.t_nagar"
        case .westMambalam: return "area.west_mambalam"
        case .thiruvanmiyur: return "area.thiruvanmiyur"
        }
    }

    var landmarkKey: String {
        switch self {
        case .tNagar: return "landmark.pondy_bazaar"
        case .westMambalam: return "landmark.mambalam_railway"
        case .thiruvanmiyur: return "landmark.thiruvanmiyur_mrts"
        }
    }
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
        case .earnings: return "tab.earnings"
        case .profile: return "tab.profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .inventory: return "basket.fill"
        case .earnings: return "indianrupeesign.circle.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Inventory & Earnings

struct VendorInventoryItem: Identifiable, Equatable {
    let id: String
    let nameKey: String
    let priceRupees: Int
    let unitKey: String
    var inStock: Bool
}

struct VendorEarningsEntry: Identifiable, Equatable {
    let id: String
    let descriptionKey: String
    let amountRupees: Int
    let timeLabel: String
}

enum VendorMockData {
    static let defaultVendorName = "vendor.name.murugan"
    static let defaultPhone = "+91 98405 12345"
    static let defaultArea: ChennaiArea = .tNagar

    static let inventory: [VendorInventoryItem] = [
        .init(id: "tomato", nameKey: "inventory.item.tomato", priceRupees: 40, unitKey: "inventory.unit.kg", inStock: true),
        .init(id: "onion", nameKey: "inventory.item.onion", priceRupees: 35, unitKey: "inventory.unit.kg", inStock: true),
        .init(id: "potato", nameKey: "inventory.item.potato", priceRupees: 30, unitKey: "inventory.unit.kg", inStock: false),
        .init(id: "spinach", nameKey: "inventory.item.spinach", priceRupees: 20, unitKey: "inventory.unit.bunch", inStock: true),
        .init(id: "banana", nameKey: "inventory.item.banana", priceRupees: 60, unitKey: "inventory.unit.dozen", inStock: true),
        .init(id: "coconut", nameKey: "inventory.item.coconut", priceRupees: 35, unitKey: "inventory.unit.each", inStock: true)
    ]

    static let earningsEntries: [VendorEarningsEntry] = [
        .init(id: "e1", descriptionKey: "earnings.entry.vegetables", amountRupees: 320, timeLabel: "9:15 AM"),
        .init(id: "e2", descriptionKey: "earnings.entry.fruits", amountRupees: 180, timeLabel: "11:40 AM"),
        .init(id: "e3", descriptionKey: "earnings.entry.milk", amountRupees: 95, timeLabel: "1:05 PM"),
        .init(id: "e4", descriptionKey: "earnings.entry.flowers", amountRupees: 210, timeLabel: "4:30 PM")
    ]

    static let todaySummary = VendorDaySummary(salesRupees: 805, customers: 18, hours: 5.5)
    static let emptyDaySummary = VendorDaySummary(salesRupees: 0, customers: 0, hours: 0.0)

    static func locationLabel(for area: ChennaiArea) -> String {
        "\(String(localized: String.LocalizationValue(area.labelKey))) · \(String(localized: String.LocalizationValue(area.landmarkKey)))"
    }
}
