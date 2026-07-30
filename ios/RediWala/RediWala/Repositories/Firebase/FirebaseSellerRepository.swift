import Combine
import FirebaseDatabase
import Foundation

/// Firebase-backed seller discovery with disk cache + local synthetic fallback.
@MainActor
final class FirebaseSellerRepository: ObservableObject, SellerRepository, FavoritesRepository {
    enum SyncState: Equatable {
        case idle
        case loading
        case live
        case offline
        case failed(message: String)
    }

    @Published private(set) var favoriteIDs: Set<String> = []
    @Published private(set) var syncState: SyncState = .idle
    @Published private(set) var lastErrorMessage: String?

    private let fallback: LocalSellerRepository
    private let customerRepository: FirebaseCustomerRepository
    private lazy var db = FirebaseDatabaseConfig.root

    private var sellersByID: [String: Seller] = [:]
    private var announcementsByVendor: [String: CachedAnnouncement] = [:]
    private var customerID: String?
    private var statusHandle: DatabaseHandle?
    private var pendingStatusUpdate: Task<Void, Never>?
    private var isListening = false

    var customerIDForProfile: String? { customerID }

    init(
        fallback: LocalSellerRepository? = nil,
        customerRepository: FirebaseCustomerRepository? = nil
    ) {
        self.fallback = fallback ?? LocalSellerRepository()
        self.customerRepository = customerRepository ?? FirebaseCustomerRepository()
        if let cachedFavorites = LocalJSONCache.load([String].self, key: CacheKeys.favorites) {
            favoriteIDs = Set(cachedFavorites)
        }
        if let cachedAnnouncements = LocalJSONCache.load([CachedAnnouncement].self, key: CacheKeys.announcements) {
            announcementsByVendor = Dictionary(uniqueKeysWithValues: cachedAnnouncements.map { ($0.vendorId, $0) })
        }
        if let cachedSellers = LocalJSONCache.load([CachedSeller].self, key: CacheKeys.sellers) {
            sellersByID = Dictionary(
                uniqueKeysWithValues: cachedSellers.compactMap { cached in
                    guard let seller = cached.asSeller() else { return nil }
                    return (seller.id, seller)
                }
            )
        }
    }

    func bootstrap(customerID: String, language: AppLanguage) async {
        FirebaseDatabaseConfig.configureIfNeeded()
        self.customerID = customerID
        _ = await customerRepository.ensureCustomer(id: customerID, language: language)
        await reload()
        startListening()
    }

    func shutdown() {
        stopListening()
    }

    func fetchNearbySellers(near neighborhood: PilotNeighborhood) async -> [Seller] {
        await fetchNearbySellers(near: neighborhood, scope: GeoContext.shared.queryScope())
    }

    func fetchNearbySellers(near neighborhood: PilotNeighborhood, scope: GeoQueryScope) async -> [Seller] {
        if sellersByID.isEmpty {
            await reload()
        }
        let source = sellersByID.isEmpty
            ? await fallback.fetchNearbySellers(near: neighborhood)
            : Array(sellersByID.values)
        let adjustedList = source
            .map { adjusted($0, near: neighborhood) }
        return GeoScopedQuery.filter(sellers: adjustedList, scope: scope)
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    func fetchSeller(id: String) async -> Seller? {
        if let seller = sellersByID[id] {
            return seller
        }
        await reload()
        if let seller = sellersByID[id] {
            return seller
        }
        return await fallback.fetchSeller(id: id)
    }

    func fetchSellers(category: SellerCategory, near neighborhood: PilotNeighborhood) async -> [Seller] {
        let all = await fetchNearbySellers(near: neighborhood)
        return all.filter { $0.category == category }
    }

    func fetchFavoriteSellers(near neighborhood: PilotNeighborhood) async -> [Seller] {
        let all = await fetchNearbySellers(near: neighborhood)
        return all.filter { favoriteIDs.contains($0.id) }.sorted { $0.name < $1.name }
    }

    @discardableResult
    func toggleFavorite(id: String) async -> Bool {
        let nowFavorite: Bool
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            nowFavorite = false
        } else {
            favoriteIDs.insert(id)
            nowFavorite = true
        }
        persistFavoritesLocally()
        await syncFavorite(id: id, isFavorite: nowFavorite)
        return nowFavorite
    }

    func isFavorite(id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func fetchAnnouncement(vendorId: String) async -> CachedAnnouncement? {
        if let cached = announcementsByVendor[vendorId] {
            return cached
        }
        await reloadAnnouncementsOnly()
        return announcementsByVendor[vendorId]
    }

    func reload() async {
        syncState = .loading
        lastErrorMessage = nil

        do {
            async let vendorsSnapshot = db.child(FirebaseRTDBPath.vendors).getData()
            async let statusSnapshot = db.child(FirebaseRTDBPath.vendorStatus).getData()
            async let locationsSnapshot = db.child(FirebaseRTDBPath.vendorLocations).getData()
            async let routesSnapshot = db.child(FirebaseRTDBPath.vendorRoutes).getData()
            async let announcementsSnapshot = db.child(FirebaseRTDBPath.vendorAnnouncements).getData()

            let vendors = FirebaseRTDBHelpers.dictionary(from: try await vendorsSnapshot)
            let statuses = FirebaseRTDBHelpers.dictionary(from: try await statusSnapshot)
            let locations = FirebaseRTDBHelpers.dictionary(from: try await locationsSnapshot)
            let routes = FirebaseRTDBHelpers.dictionary(from: try await routesSnapshot)
            let announcements = FirebaseRTDBHelpers.dictionary(from: try await announcementsSnapshot)

            var merged: [String: Seller] = [:]
            var announcementRecords: [CachedAnnouncement] = []

            for (vendorID, vendor) in vendors {
                let announcement = announcements[vendorID]
                let seller = FirebaseSellerMapper.mapSeller(
                    id: vendorID,
                    vendor: vendor,
                    status: statuses[vendorID],
                    location: locations[vendorID],
                    route: routes[vendorID],
                    announcement: announcement,
                    near: .tNagar
                )
                if let seller {
                    merged[vendorID] = seller
                }
                if let announcement {
                    announcementRecords.append(FirebaseSellerMapper.mapAnnouncement(vendorId: vendorID, value: announcement))
                }
            }

            if !merged.isEmpty {
                sellersByID = merged
                LocalJSONCache.save(merged.values.map(CachedSeller.from), key: CacheKeys.sellers)
            }

            if !announcementRecords.isEmpty {
                announcementsByVendor = Dictionary(uniqueKeysWithValues: announcementRecords.map { ($0.vendorId, $0) })
                LocalJSONCache.save(announcementRecords, key: CacheKeys.announcements)
            }

            await reloadFavorites()
            syncState = .live
        } catch {
            lastErrorMessage = error.localizedDescription
            syncState = sellersByID.isEmpty ? .offline : .failed(message: error.localizedDescription)
        }
    }

    func startListening() {
        guard !isListening else { return }
        isListening = true
        statusHandle = db.child(FirebaseRTDBPath.vendorStatus).observe(.value) { [weak self] snapshot in
            guard let self else { return }
            let statuses = FirebaseRTDBHelpers.dictionary(from: snapshot)
            self.pendingStatusUpdate?.cancel()
            self.pendingStatusUpdate = Task { @MainActor [weak self] in
                self?.applyLiveStatusUpdates(statuses)
            }
        }
    }

    func stopListening() {
        pendingStatusUpdate?.cancel()
        pendingStatusUpdate = nil
        if let statusHandle {
            db.child(FirebaseRTDBPath.vendorStatus).removeObserver(withHandle: statusHandle)
        }
        statusHandle = nil
        isListening = false
    }

    private func reloadAnnouncementsOnly() async {
        do {
            let snapshot = try await db.child(FirebaseRTDBPath.vendorAnnouncements).getData()
            let announcements = FirebaseRTDBHelpers.dictionary(from: snapshot)
            var records: [CachedAnnouncement] = []
            for (vendorID, value) in announcements {
                records.append(FirebaseSellerMapper.mapAnnouncement(vendorId: vendorID, value: value))
            }
            if !records.isEmpty {
                announcementsByVendor = Dictionary(uniqueKeysWithValues: records.map { ($0.vendorId, $0) })
                LocalJSONCache.save(records, key: CacheKeys.announcements)
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func reloadFavorites() async {
        guard let customerID else { return }
        do {
            let snapshot = try await db.child(FirebaseRTDBPath.customerFavorites(customerID)).getData()
            guard snapshot.exists(), let raw = snapshot.value as? [String: Any] else { return }
            let ids = raw.compactMap { key, value -> String? in
                (value as? Bool) == true ? key : nil
            }
            favoriteIDs = Set(ids)
            persistFavoritesLocally()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func syncFavorite(id: String, isFavorite: Bool) async {
        guard let customerID else { return }
        do {
            try await db
                .child(FirebaseRTDBPath.customerFavorite(customerId: customerID, vendorId: id))
                .setValue(isFavorite)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func persistFavoritesLocally() {
        LocalJSONCache.save(Array(favoriteIDs), key: CacheKeys.favorites)
    }

    private func applyLiveStatusUpdates(_ statuses: [String: [String: Any]]) {
        guard !statuses.isEmpty else { return }
        var changed = false
        for (vendorID, status) in statuses {
            guard let seller = sellersByID[vendorID] else { continue }
            let isLiveFlag = (status["isLive"] as? Bool) ?? false
            let expires = FirebaseRTDBHelpers.date(from: status["presenceExpiresAt"])
            let isLive = isLiveFlag && (expires == nil || expires! > Date())
            if seller.isLive != isLive || seller.presenceExpiresAt != expires {
                var updated = seller.with(isLive: isLive)
                updated.presenceExpiresAt = expires
                sellersByID[vendorID] = updated
                changed = true
            }
        }
        if changed {
            LocalJSONCache.save(sellersByID.values.map(CachedSeller.from), key: CacheKeys.sellers)
            objectWillChange.send()
        }
    }

    private func adjusted(_ seller: Seller, near neighborhood: PilotNeighborhood) -> Seller {
        let meters = SellerDistance.meters(
            from: neighborhood.coordinate,
            toLatitude: seller.latitude,
            toLongitude: seller.longitude
        )
        return seller.with(distanceMeters: meters)
    }
}
