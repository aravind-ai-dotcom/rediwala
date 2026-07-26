import Combine
import Foundation

/// In-memory Chennai pilot repository. Favorites are session-scoped.
@MainActor
final class LocalSellerRepository: ObservableObject, SellerRepository {
    @Published private(set) var favoriteIDs: Set<String> = []

    private let sellers: [Seller]

    init(sellers: [Seller]? = nil) {
        self.sellers = sellers ?? SyntheticChennaiData.sellers
    }

    func fetchNearbySellers() async -> [Seller] {
        await simulateLatency()
        return sellers.sorted { $0.distanceMeters < $1.distanceMeters }
    }

    func fetchSeller(id: String) async -> Seller? {
        await simulateLatency()
        return sellers.first { $0.id == id }
    }

    func fetchSellers(category: SellerCategory) async -> [Seller] {
        await simulateLatency()
        return sellers
            .filter { $0.category == category }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    func fetchFavoriteSellers() async -> [Seller] {
        await simulateLatency()
        return sellers
            .filter { favoriteIDs.contains($0.id) }
            .sorted { $0.name < $1.name }
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

    private func simulateLatency(short: Bool = false) async {
        let nanoseconds: UInt64 = short ? 40_000_000 : 120_000_000
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
