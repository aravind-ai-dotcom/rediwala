import Foundation

/// Abstraction for seller discovery data. Swap `LocalSellerRepository`
/// with a future `FirebaseSellerRepository` without rewriting UI.
protocol SellerRepository: AnyObject {
    func fetchNearbySellers() async -> [Seller]
    func fetchSeller(id: String) async -> Seller?
    func fetchSellers(category: SellerCategory) async -> [Seller]
    func fetchFavoriteSellers() async -> [Seller]
    @discardableResult
    func toggleFavorite(id: String) async -> Bool
    func isFavorite(id: String) -> Bool
    var favoriteIDs: Set<String> { get }
}
