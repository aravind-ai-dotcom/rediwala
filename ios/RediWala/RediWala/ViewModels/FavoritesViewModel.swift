import Combine
import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    let repository: FirebaseSellerRepository

    private var cancellables = Set<AnyCancellable>()

    init(repository: FirebaseSellerRepository) {
        self.repository = repository
        repository.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var favoriteIDs: Set<String> {
        repository.favoriteIDs
    }

    func isFavorite(_ sellerID: String) -> Bool {
        repository.isFavorite(id: sellerID)
    }

    func toggle(_ sellerID: String) {
        Task {
            await repository.toggleFavorite(id: sellerID)
        }
    }

    func favorites(from sellers: [Seller]) -> [Seller] {
        sellers.filter { favoriteIDs.contains($0.id) }
    }

    func fetchFavorites(near neighborhood: PilotNeighborhood = .tNagar) async -> [Seller] {
        await repository.fetchFavoriteSellers(near: neighborhood)
    }
}
