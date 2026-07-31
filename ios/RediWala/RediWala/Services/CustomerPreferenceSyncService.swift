import FirebaseDatabase
import Foundation

/// Bidirectional UID-scoped preference sync to RTDB (`customers/{uid}` + `customer_settings/{uid}`).
@MainActor
enum CustomerPreferenceSyncService {
    private static var db: DatabaseReference { FirebaseDatabaseConfig.root }
    private static var debounceTask: Task<Void, Never>?

    /// Debounced write of local preference stores for the signed-in customer.
    static func scheduleSync() {
        guard let uid = CustomerIdentityStore.loadUID() else { return }
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await pushAll(uid: uid)
        }
    }

    static func pushAll(uid: String) async {
        FirebaseDatabaseConfig.configureIfNeeded()

        let needs = CustomerNeedsStore.shared.selected.map(\.rawValue).sorted()
        let follows = CustomerVendorFollowStore.shared.myVendorIDs.sorted()
        let language = UserDefaults.standard.string(forKey: "customer.app.language") ?? AppLanguage.english.rawValue
        let place = CustomerPlaceStore.shared.activePlace.rawValue
        let neighborhood = CustomerNeighborhoodStore.shared.homeNeighborhood
        let recentlyViewed = CustomerRecentlyViewedStore.shared.ids
        let relationships = CustomerRelationshipStore.shared.exportPayload()

        let customerPatch: [String: Any] = [
            "todaysNeeds": needs,
            "followedVendorIds": follows,
            "savedVendorIds": follows,
            "preferredLanguage": language,
            "homeNeighborhood": FirebaseIDMap.firebaseID(for: neighborhood),
            "updatedAt": FirebaseRTDBHelpers.isoString(Date())
        ]

        let settingsPayload: [String: Any] = [
            "activePlace": place,
            "preferredLanguage": language,
            "todaysNeeds": needs,
            "followedVendorIds": follows,
            "recentlyViewedVendorIds": recentlyViewed,
            "relationships": relationships,
            "notificationsEnabled": CustomerNotificationPreferenceStore.shared.areEnabled,
            "updatedAt": FirebaseRTDBHelpers.isoString(Date())
        ]

        do {
            try await db.child(FirebaseRTDBPath.customer(uid)).updateChildValues(customerPatch)
            try await db.child(FirebaseRTDBPath.customerSettings(uid)).setValue(settingsPayload)
        } catch {
            // Offline / rules: local stores remain source of truth until retry.
        }
    }

    static func pullSettings(uid: String) async {
        FirebaseDatabaseConfig.configureIfNeeded()
        do {
            let snapshot = try await db.child(FirebaseRTDBPath.customerSettings(uid)).getData()
            guard snapshot.exists(), let value = snapshot.value as? [String: Any] else { return }

            if let placeRaw = value["activePlace"] as? String,
               let place = CustomerPlaceKind(rawValue: placeRaw) {
                CustomerPlaceStore.shared.activePlace = place
            }
            if let enabled = value["notificationsEnabled"] as? Bool {
                CustomerNotificationPreferenceStore.shared.areEnabled = enabled
            }
            if let recent = value["recentlyViewedVendorIds"] as? [String] {
                CustomerRecentlyViewedStore.shared.replace(with: recent)
            }
            if let relationships = value["relationships"] as? [String: Any] {
                CustomerRelationshipStore.shared.importPayload(relationships)
            }
        } catch {
            // Best-effort restore.
        }
    }
}
