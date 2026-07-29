import Combine
import Foundation

/// In-memory Chennai pilot repository used as offline / preview fallback.
@MainActor
final class LocalSellerRepository: ObservableObject, SellerRepository, FavoritesRepository {
    @Published private(set) var favoriteIDs: Set<String> = []

    private let sellers: [Seller]

    init(sellers: [Seller]? = nil) {
        self.sellers = sellers ?? SyntheticChennaiData.sellers
    }

    func fetchNearbySellers(near neighborhood: PilotNeighborhood) async -> [Seller] {
        await simulateLatency()
        return sellers
            .map { adjusted($0, near: neighborhood) }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    func fetchSeller(id: String) async -> Seller? {
        await simulateLatency()
        return sellers.first { $0.id == id }
    }

    func fetchSellers(category: SellerCategory, near neighborhood: PilotNeighborhood) async -> [Seller] {
        await simulateLatency()
        return sellers
            .filter { $0.category == category }
            .map { adjusted($0, near: neighborhood) }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    func fetchFavoriteSellers(near neighborhood: PilotNeighborhood) async -> [Seller] {
        await simulateLatency()
        return sellers
            .filter { favoriteIDs.contains($0.id) }
            .map { adjusted($0, near: neighborhood) }
            .sorted { $0.name < $1.name }
    }

    /// Compatibility for call sites that still omit neighborhood.
    func fetchFavoriteSellers() async -> [Seller] {
        await fetchFavoriteSellers(near: .tNagar)
    }

    @discardableResult
    func toggleFavorite(id: String) async -> Bool {
        await simulateLatency(short: true)
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            return false
        } else {
            favoriteIDs.insert(id)
            return true
        }
    }

    func isFavorite(id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func reload() async {}

    private func adjusted(_ seller: Seller, near neighborhood: PilotNeighborhood) -> Seller {
        let meters = SellerDistance.meters(
            from: neighborhood.coordinate,
            toLatitude: seller.latitude,
            toLongitude: seller.longitude
        )
        return seller.with(distanceMeters: meters)
    }

    private func simulateLatency(short: Bool = false) async {
        let nanoseconds: UInt64 = short ? 40_000_000 : 120_000_000
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
