import Combine
import Foundation

/// Favorites framed as neighborhood relationships (weekly milkman, flower seller, …).
struct VendorRelationship: Codable, Equatable, Identifiable {
    var id: String { vendorID }
    var vendorID: String
    var label: String
    var favoritedAt: Date
    var lastInteractionAt: Date
    var interactionCount: Int
    var isArchived: Bool

    static func defaultLabel(for category: SellerCategory?) -> String {
        switch category {
        case .milk: return "Weekly milkman"
        case .flowers: return "Flower seller"
        case .laundry: return "Laundry"
        case .tailor: return "Tailor"
        case .vegetables: return "Vegetable vendor"
        case .ironing: return "Ironing"
        case .fish: return "Fish seller"
        case .fruits: return "Fruit seller"
        case .cableBill: return "Cable collection"
        case .foodTruck: return "Food truck"
        default: return "Neighborhood vendor"
        }
    }
}

@MainActor
final class CustomerRelationshipStore: ObservableObject {
    static let shared = CustomerRelationshipStore()

    @Published private(set) var relationships: [String: VendorRelationship] = [:]

    private let key = "customer.relationships.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: VendorRelationship].self, from: data) {
            relationships = decoded
        }
    }

    func relationship(for vendorID: String) -> VendorRelationship? {
        relationships[vendorID]
    }

    func label(for vendorID: String, category: SellerCategory?) -> String {
        if let existing = relationships[vendorID]?.label, !existing.isEmpty {
            return existing
        }
        return VendorRelationship.defaultLabel(for: category)
    }

    func ensureFavorite(vendorID: String, category: SellerCategory?) {
        if var existing = relationships[vendorID] {
            existing.isArchived = false
            existing.lastInteractionAt = Date()
            existing.interactionCount += 1
            if existing.label.isEmpty {
                existing.label = VendorRelationship.defaultLabel(for: category)
            }
            relationships[vendorID] = existing
        } else {
            relationships[vendorID] = VendorRelationship(
                vendorID: vendorID,
                label: VendorRelationship.defaultLabel(for: category),
                favoritedAt: Date(),
                lastInteractionAt: Date(),
                interactionCount: 1,
                isArchived: false
            )
        }
        persist()
        CustomerPreferenceSyncService.scheduleSync()
    }

    func removeFavorite(vendorID: String) {
        relationships.removeValue(forKey: vendorID)
        persist()
        CustomerPreferenceSyncService.scheduleSync()
    }

    func rename(vendorID: String, label: String) {
        guard var existing = relationships[vendorID] else { return }
        existing.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        existing.lastInteractionAt = Date()
        relationships[vendorID] = existing
        persist()
        CustomerPreferenceSyncService.scheduleSync()
    }

    func recordInteraction(vendorID: String) {
        guard var existing = relationships[vendorID] else { return }
        existing.lastInteractionAt = Date()
        existing.interactionCount += 1
        relationships[vendorID] = existing
        persist()
    }

    func activeRelationships() -> [VendorRelationship] {
        relationships.values
            .filter { !$0.isArchived }
            .sorted { $0.lastInteractionAt > $1.lastInteractionAt }
    }

    func exportPayload() -> [String: Any] {
        var payload: [String: Any] = [:]
        for (id, rel) in relationships {
            payload[id] = [
                "vendorID": rel.vendorID,
                "label": rel.label,
                "favoritedAt": FirebaseRTDBHelpers.isoString(rel.favoritedAt),
                "lastInteractionAt": FirebaseRTDBHelpers.isoString(rel.lastInteractionAt),
                "interactionCount": rel.interactionCount,
                "isArchived": rel.isArchived
            ]
        }
        return payload
    }

    func importPayload(_ raw: [String: Any]) {
        var next = relationships
        for (id, value) in raw {
            guard let dict = value as? [String: Any] else { continue }
            let favorited = ISO8601DateFormatter().date(from: dict["favoritedAt"] as? String ?? "") ?? Date()
            let last = ISO8601DateFormatter().date(from: dict["lastInteractionAt"] as? String ?? "") ?? favorited
            next[id] = VendorRelationship(
                vendorID: (dict["vendorID"] as? String) ?? id,
                label: (dict["label"] as? String) ?? "Neighborhood vendor",
                favoritedAt: favorited,
                lastInteractionAt: last,
                interactionCount: (dict["interactionCount"] as? Int) ?? 1,
                isArchived: (dict["isArchived"] as? Bool) ?? false
            )
        }
        relationships = next
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(relationships) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

@MainActor
final class CustomerRecentlyViewedStore: ObservableObject {
    static let shared = CustomerRecentlyViewedStore()

    @Published private(set) var ids: [String] = []

    private let maxCount = 20

    private init() {
        if let cached = LocalJSONCache.load([String].self, key: CacheKeys.recentlyViewed) {
            ids = cached
        }
    }

    func record(vendorID: String) {
        var next = ids.filter { $0 != vendorID }
        next.insert(vendorID, at: 0)
        if next.count > maxCount {
            next = Array(next.prefix(maxCount))
        }
        ids = next
        LocalJSONCache.save(ids, key: CacheKeys.recentlyViewed)
        CustomerPreferenceSyncService.scheduleSync()
    }

    func replace(with vendorIDs: [String]) {
        ids = Array(vendorIDs.prefix(maxCount))
        LocalJSONCache.save(ids, key: CacheKeys.recentlyViewed)
    }
}

@MainActor
final class CustomerNotificationPreferenceStore: ObservableObject {
    static let shared = CustomerNotificationPreferenceStore()

    private let key = "customer.notifications.enabled.v1"

    @Published var areEnabled: Bool {
        didSet {
            UserDefaults.standard.set(areEnabled, forKey: key)
            CustomerPreferenceSyncService.scheduleSync()
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: key) == nil {
            areEnabled = true
        } else {
            areEnabled = UserDefaults.standard.bool(forKey: key)
        }
    }
}
