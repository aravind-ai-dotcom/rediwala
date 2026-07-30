import Foundation

// MARK: - SellerRepository

/// Discovery data. UI must not know if this is local or Firebase.
protocol SellerRepository: AnyObject {
    func fetchNearbySellers(near neighborhood: PilotNeighborhood) async -> [Seller]
    func fetchNearbySellers(near neighborhood: PilotNeighborhood, scope: GeoQueryScope) async -> [Seller]
    func fetchSeller(id: String) async -> Seller?
    func fetchSellers(category: SellerCategory, near neighborhood: PilotNeighborhood) async -> [Seller]
    /// Starts realtime listeners when supported. Safe to call repeatedly.
    func startListening()
    func stopListening()
}

extension SellerRepository {
    func fetchNearbySellers() async -> [Seller] {
        await fetchNearbySellers(near: .tNagar)
    }

    func fetchNearbySellers(near neighborhood: PilotNeighborhood, scope: GeoQueryScope) async -> [Seller] {
        await fetchNearbySellers(near: neighborhood)
    }

    func fetchSellers(category: SellerCategory) async -> [Seller] {
        await fetchSellers(category: category, near: .tNagar)
    }

    func startListening() {}
    func stopListening() {}
}

// MARK: - FavoritesRepository

protocol FavoritesRepository: AnyObject {
    var favoriteIDs: Set<String> { get }
    func isFavorite(id: String) -> Bool
    @discardableResult
    func toggleFavorite(id: String) async -> Bool
    func fetchFavoriteSellers(near neighborhood: PilotNeighborhood) async -> [Seller]
    func reload() async
}

// MARK: - CustomerRepository

protocol CustomerRepository: AnyObject {
    func ensureCustomer(id: String, language: AppLanguage) async -> PersistentCustomerProfile
    func fetchCustomer(id: String) async -> PersistentCustomerProfile?
    func saveCustomer(_ profile: PersistentCustomerProfile) async
    func touchLastSeen(id: String) async
}

// MARK: - CategoryRepository

protocol CategoryRepository: AnyObject {
    func fetchCategoryGroups() async -> [CachedCategoryGroupRecord]
    func fetchCategories() async -> [CachedCategoryRecord]
    func reload() async
}

// MARK: - AnnouncementRepository

protocol AnnouncementRepository: AnyObject {
    func fetchAnnouncement(vendorId: String) async -> CachedAnnouncement?
    func fetchAll() async -> [CachedAnnouncement]
    func reload() async
}
