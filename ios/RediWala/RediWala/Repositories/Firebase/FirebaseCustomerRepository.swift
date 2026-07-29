import FirebaseDatabase
import Foundation

@MainActor
final class FirebaseCustomerRepository: CustomerRepository {
    private var db: DatabaseReference { FirebaseDatabaseConfig.root }

    func ensureCustomer(id: String, language: AppLanguage) async -> PersistentCustomerProfile {
        if let existing = await fetchCustomer(id: id) {
            return existing
        }
        let profile = PersistentCustomerProfile.makeNew(id: id, language: language)
        await saveCustomer(profile)
        return profile
    }

    func fetchCustomer(id: String) async -> PersistentCustomerProfile? {
        if let cached = LocalJSONCache.load(PersistentCustomerProfile.self, key: CacheKeys.customerProfile),
           cached.id == id {
            // Return cache quickly; remote refresh happens separately.
        }

        do {
            let snapshot = try await db.child(FirebaseRTDBPath.customer(id)).getData()
            guard snapshot.exists(), let value = snapshot.value as? [String: Any] else {
                return LocalJSONCache.load(PersistentCustomerProfile.self, key: CacheKeys.customerProfile)
            }
            let profile = mapCustomer(id: id, value: value)
            LocalJSONCache.save(profile, key: CacheKeys.customerProfile)
            return profile
        } catch {
            return LocalJSONCache.load(PersistentCustomerProfile.self, key: CacheKeys.customerProfile)
        }
    }

    func saveCustomer(_ profile: PersistentCustomerProfile) async {
        LocalJSONCache.save(profile, key: CacheKeys.customerProfile)
        let payload: [String: Any] = [
            "id": profile.id,
            "displayName": profile.displayName,
            "cityId": profile.cityId,
            "neighborhoodId": FirebaseIDMap.firebaseID(for: profile.selectedNeighborhood),
            "languages": [profile.preferredLanguage.rawValue],
            "photoURL": profile.photoURL as Any,
            "phone": profile.phone as Any,
            "createdAt": FirebaseRTDBHelpers.isoString(profile.createdDate),
            "lastSeen": FirebaseRTDBHelpers.isoString(profile.lastSeen)
        ]
        do {
            try await db.child(FirebaseRTDBPath.customer(profile.id)).setValue(payload)
        } catch {
            // Best-effort sync; local cache remains source when offline.
        }
    }

    func touchLastSeen(id: String) async {
        guard var profile = await fetchCustomer(id: id) else { return }
        profile.lastSeen = Date()
        await saveCustomer(profile)
    }

    private func mapCustomer(id: String, value: [String: Any]) -> PersistentCustomerProfile {
        let neighborhood = FirebaseIDMap.neighborhood(fromFirebase: value["neighborhoodId"] as? String)
        let languages = (value["languages"] as? [String]) ?? ["en"]
        let preferred = AppLanguage(rawValue: languages.first ?? "en") ?? .english
        let created = ISO8601DateFormatter().date(from: value["createdAt"] as? String ?? "") ?? Date()
        let lastSeen = ISO8601DateFormatter().date(from: value["lastSeen"] as? String ?? "") ?? Date()

        return PersistentCustomerProfile(
            id: id,
            displayName: (value["displayName"] as? String) ?? "Neighbor",
            preferredLanguage: preferred,
            selectedNeighborhood: neighborhood,
            favoriteCategories: [],
            favorites: [],
            createdDate: created,
            lastSeen: lastSeen,
            photoURL: value["photoURL"] as? String,
            cityId: (value["cityId"] as? String) ?? "chennai",
            phone: value["phone"] as? String
        )
    }
}
