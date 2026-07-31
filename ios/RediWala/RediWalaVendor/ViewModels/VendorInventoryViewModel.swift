import Combine
import Foundation

@MainActor
final class VendorInventoryViewModel: ObservableObject {
    @Published var items: [VendorInventoryItem]
    private let vendorID: String
    private let category: VendorCategory

    init(category: VendorCategory = .vegetables, vendorID: String = VendorIdentityStore.vendorID, items: [VendorInventoryItem]? = nil) {
        self.category = category
        self.vendorID = vendorID
        self.items = items ?? VendorBusinessDayStore.loadOfferings(vendorID: vendorID, category: category)
    }

    var inStockCount: Int {
        items.filter(\.inStock).count
    }

    func toggleStock(for item: VendorInventoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].inStock.toggle()
        items[index].availableToday = items[index].inStock
        persist()
    }

    func persist() {
        VendorBusinessDayStore.saveOfferings(items, vendorID: vendorID)
    }
}
