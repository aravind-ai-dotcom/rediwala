import Combine
import Foundation

@MainActor
final class VendorDetailViewModel: ObservableObject {
    @Published private(set) var seller: Seller?
    @Published private(set) var isLoading = false

    private let sellerID: String
    private let repository: SellerRepository

    /// Compatibility alias.
    var vendor: Seller? { seller }

    init(vendorID: String, repository: SellerRepository) {
        self.sellerID = vendorID
        self.repository = repository
    }

    func load() async {
        isLoading = true
        seller = await repository.fetchSeller(id: sellerID)
        isLoading = false
    }
}
