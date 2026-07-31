import Combine
import Foundation

// MARK: - Today's Needs

enum NeedCategoryGroup: String, CaseIterable, Identifiable {
    case freshFood
    case homeServices
    case collections
    case streetFood

    var id: String { rawValue }
    var titleKey: String { "needGroup.\(rawValue)" }

    var tint: CategoryTint {
        switch self {
        case .freshFood: return .primary
        case .homeServices: return .info
        case .collections: return .accent
        case .streetFood: return .accent
        }
    }

    var needs: [CustomerNeedItem] {
        CustomerNeedItem.allCases.filter { $0.group == self }
    }
}

/// Things a customer wants help with today — multi-select, day-scoped persistence.
enum CustomerNeedItem: String, CaseIterable, Identifiable, Codable {
    case vegetables
    case fruits
    case bananas
    case flowers
    case freshFish
    case milk
    case tenderCoconut
    case eggs
    case tea
    case breakfast
    case snacks
    case foodTruck
    case knifeSharpening
    case cobbler
    case tailor
    case ironing
    case laundryPickup
    case sofaRepair
    case repairs
    case recyclingPickup
    case newspaperCollection
    case plasticCollection
    case scrapBuyer
    case cableBill
    case waterCan
    case gasCylinder
    case householdRepair
    case coconut
    case kulfi

    var id: String { rawValue }
    var titleKey: String { "need.\(rawValue)" }

    var group: NeedCategoryGroup {
        switch self {
        case .vegetables, .fruits, .bananas, .flowers, .freshFish, .milk, .tenderCoconut, .eggs, .coconut:
            return .freshFood
        case .laundryPickup, .ironing, .tailor, .cobbler, .knifeSharpening, .sofaRepair, .repairs, .householdRepair:
            return .homeServices
        case .newspaperCollection, .plasticCollection, .scrapBuyer, .recyclingPickup, .waterCan, .cableBill, .gasCylinder:
            return .collections
        case .tea, .breakfast, .snacks, .foodTruck, .kulfi:
            return .streetFood
        }
    }

    var systemImage: String {
        switch self {
        case .vegetables: return "basket.fill"
        case .fruits, .bananas, .coconut: return "carrot.fill"
        case .tenderCoconut: return "circle.fill"
        case .flowers: return "leaf.fill"
        case .freshFish: return "fish.fill"
        case .milk: return "waterbottle.fill"
        case .eggs: return "circle.inset.filled"
        case .tea: return "mug.fill"
        case .breakfast: return "fork.knife"
        case .snacks, .kulfi: return "snowflake"
        case .foodTruck: return "box.truck.fill"
        case .knifeSharpening: return "diamond.fill"
        case .tailor: return "scissors"
        case .cobbler: return "hammer.fill"
        case .ironing: return "tshirt.fill"
        case .laundryPickup: return "washer.fill"
        case .sofaRepair, .repairs, .householdRepair: return "wrench.and.screwdriver.fill"
        case .recyclingPickup, .plasticCollection, .scrapBuyer: return "arrow.3.trianglepath"
        case .newspaperCollection: return "newspaper.fill"
        case .cableBill: return "tv.fill"
        case .waterCan: return "drop.fill"
        case .gasCylinder: return "flame.circle.fill"
        }
    }

    var matchingCategories: [SellerCategory] {
        switch self {
        case .vegetables: return [.vegetables]
        case .fruits, .bananas: return [.fruits]
        case .flowers: return [.flowers]
        case .freshFish: return [.fish]
        case .milk, .eggs: return [.milk]
        case .tenderCoconut, .coconut: return [.tenderCoconut, .fruits]
        case .tea, .breakfast, .snacks: return [.bakery, .foodTruck, .kulfi]
        case .foodTruck: return [.foodTruck, .bakery]
        case .kulfi: return [.kulfi, .iceCream]
        case .knifeSharpening: return [.knifeSharpening]
        case .cobbler: return [.cobbler]
        case .tailor: return [.tailor]
        case .ironing, .laundryPickup: return [.ironing, .laundry]
        case .sofaRepair, .repairs, .householdRepair: return [.sofaRepair, .householdRepair, .electricalRepair]
        case .recyclingPickup, .plasticCollection, .scrapBuyer: return [.plastic, .cardboard, .metalScrap]
        case .newspaperCollection: return [.oldNewspapers]
        case .cableBill: return [.cableBill]
        case .waterCan: return [.waterCan]
        case .gasCylinder: return [.gasCylinder]
        }
    }
}

@MainActor
final class CustomerNeedsStore: ObservableObject {
    static let shared = CustomerNeedsStore()

    @Published private(set) var selected: Set<CustomerNeedItem> {
        didSet { persistToday() }
    }

    @Published private(set) var completed: Set<CustomerNeedItem> = []

    private let todayKey = "customer.todays_needs.v2"
    private let dayStampKey = "customer.todays_needs.day.v2"
    private let yesterdayKey = "customer.yesterdays_needs.v2"
    private let completedKey = "customer.todays_needs.completed.v2"

    private init() {
        Self.migrateIfNeeded(todayKey: todayKey, dayStampKey: dayStampKey)
        let today = Self.dayStamp()
        let savedDay = UserDefaults.standard.string(forKey: dayStampKey)
        if savedDay != today {
            // Roll yesterday forward, start fresh for a new calendar day.
            if let previous = UserDefaults.standard.array(forKey: todayKey) as? [String] {
                UserDefaults.standard.set(previous, forKey: yesterdayKey)
            }
            selected = []
            completed = []
            UserDefaults.standard.set(today, forKey: dayStampKey)
            UserDefaults.standard.set([String](), forKey: todayKey)
            UserDefaults.standard.set([String](), forKey: completedKey)
        } else if let raw = UserDefaults.standard.array(forKey: todayKey) as? [String] {
            selected = Set(raw.compactMap(CustomerNeedItem.init(rawValue:)))
            if let done = UserDefaults.standard.array(forKey: completedKey) as? [String] {
                completed = Set(done.compactMap(CustomerNeedItem.init(rawValue:)))
            } else {
                completed = []
            }
        } else {
            selected = [.vegetables]
            completed = []
        }
    }

    func toggle(_ need: CustomerNeedItem) {
        if selected.contains(need) {
            selected.remove(need)
            completed.remove(need)
        } else {
            selected.insert(need)
        }
        persistCompleted()
    }

    func isSelected(_ need: CustomerNeedItem) -> Bool {
        selected.contains(need)
    }

    func isCompleted(_ need: CustomerNeedItem) -> Bool {
        completed.contains(need)
    }

    func markCompleted(_ need: CustomerNeedItem) {
        guard selected.contains(need) else { return }
        completed.insert(need)
        persistCompleted()
    }

    func clearToday() {
        selected = []
        completed = []
        persistCompleted()
    }

    func replaceToday(with needs: [CustomerNeedItem]) {
        selected = Set(needs)
        completed = []
        persistCompleted()
    }

    func reuseYesterday() {
        guard let raw = UserDefaults.standard.array(forKey: yesterdayKey) as? [String] else { return }
        selected = Set(raw.compactMap(CustomerNeedItem.init(rawValue:)))
        completed = []
        persistCompleted()
    }

    var matchingCategories: Set<SellerCategory> {
        Set(selected.subtracting(completed).flatMap(\.matchingCategories))
    }

    var activeNeeds: [CustomerNeedItem] {
        CustomerNeedItem.allCases.filter { selected.contains($0) && !completed.contains($0) }
    }

    private func persistToday() {
        UserDefaults.standard.set(selected.map(\.rawValue).sorted(), forKey: todayKey)
        UserDefaults.standard.set(Self.dayStamp(), forKey: dayStampKey)
        CustomerPreferenceSyncService.scheduleSync()
    }

    private func persistCompleted() {
        UserDefaults.standard.set(completed.map(\.rawValue).sorted(), forKey: completedKey)
    }

    private static func migrateIfNeeded(todayKey: String, dayStampKey: String) {
        let legacyKey = "customer.todays_needs.v1"
        guard UserDefaults.standard.array(forKey: todayKey) == nil,
              let legacy = UserDefaults.standard.array(forKey: legacyKey) as? [String] else { return }
        UserDefaults.standard.set(legacy, forKey: todayKey)
        UserDefaults.standard.set(dayStamp(), forKey: dayStampKey)
    }

    private static func dayStamp() -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Follow / Track vendors

enum VendorFollowState: String, Codable, Equatable {
    case none
    case following
    case tracked
    case muted
    case hidden
}

struct VendorFollowRecord: Codable, Equatable {
    var vendorID: String
    var state: VendorFollowState
    var isFavorite: Bool
    var updatedAt: Date
}

@MainActor
final class CustomerVendorFollowStore: ObservableObject {
    static let shared = CustomerVendorFollowStore()

    @Published private(set) var records: [String: VendorFollowRecord] = [:]

    private let key = "customer.vendor_follows.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: VendorFollowRecord].self, from: data) {
            records = decoded
        }
    }

    func replaceFollows(followed: [String], saved: [String] = []) {
        var next: [String: VendorFollowRecord] = [:]
        for id in followed {
            next[id] = VendorFollowRecord(vendorID: id, state: .tracked, isFavorite: true, updatedAt: Date())
        }
        for id in saved where next[id] == nil {
            next[id] = VendorFollowRecord(vendorID: id, state: .following, isFavorite: true, updatedAt: Date())
        }
        records = next
        persist()
    }

    func clearAll() {
        records = [:]
        persist()
    }

    func state(for vendorID: String) -> VendorFollowState {
        records[vendorID]?.state ?? .none
    }

    func isTracked(_ vendorID: String) -> Bool {
        let s = state(for: vendorID)
        return s == .tracked || s == .following
    }

    func isFollowing(_ vendorID: String) -> Bool {
        let s = state(for: vendorID)
        return s == .following || s == .tracked
    }

    func isMuted(_ vendorID: String) -> Bool {
        state(for: vendorID) == .muted
    }

    func isHidden(_ vendorID: String) -> Bool {
        state(for: vendorID) == .hidden
    }

    func follow(_ vendorID: String) {
        set(vendorID, state: .following)
    }

    func track(_ vendorID: String) {
        set(vendorID, state: .tracked)
    }

    func unfollow(_ vendorID: String) {
        set(vendorID, state: .none)
    }

    func mute(_ vendorID: String) {
        set(vendorID, state: .muted)
    }

    func hide(_ vendorID: String) {
        set(vendorID, state: .hidden)
    }

    func toggleFollow(_ vendorID: String) {
        if isFollowing(vendorID) {
            unfollow(vendorID)
        } else {
            track(vendorID)
        }
    }

    var myVendorIDs: [String] {
        records.values
            .filter { $0.state == .following || $0.state == .tracked }
            .map(\.vendorID)
    }

    private func set(_ vendorID: String, state: VendorFollowState) {
        var record = records[vendorID] ?? VendorFollowRecord(
            vendorID: vendorID,
            state: .none,
            isFavorite: false,
            updatedAt: Date()
        )
        record.state = state
        record.updatedAt = Date()
        if state == .none {
            records.removeValue(forKey: vendorID)
        } else {
            records[vendorID] = record
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
        CustomerPreferenceSyncService.scheduleSync()
    }
}

// MARK: - Service presentation

enum CustomerServiceMode: String, Codable, CaseIterable {
    case mobile
    case stationary
    case scheduled

    var titleKey: String { "serviceMode.\(rawValue)" }

    var mapBehaviorKey: String {
        switch self {
        case .mobile: return "serviceBehavior.route"
        case .stationary: return "serviceBehavior.fixed"
        case .scheduled: return "serviceBehavior.rounds"
        }
    }

    /// Default presence confirmation interval for this mode.
    var presenceCheckIntervalMinutes: Int {
        switch self {
        case .mobile: return 120
        case .stationary: return 60
        case .scheduled: return 90
        }
    }
}

enum ServiceBehaviorProfile: String, Codable {
    case routeBased
    case buildingProgress
    case streetProgress
    case fixedLocation

    static func profile(for category: SellerCategory, mode: CustomerServiceMode) -> ServiceBehaviorProfile {
        switch category {
        case .laundry, .ironing, .cableBill:
            return mode == .stationary ? .fixedLocation : .buildingProgress
        case .vegetables, .fruits, .flowers, .fish, .milk:
            return mode == .stationary ? .fixedLocation : .routeBased
        case .bakery, .kulfi, .roastedCorn, .peanuts, .foodTruck:
            return .fixedLocation
        default:
            return mode == .scheduled ? .streetProgress : .routeBased
        }
    }
}
