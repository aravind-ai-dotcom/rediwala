import Combine
import Foundation

@MainActor
final class VendorInventoryViewModel: ObservableObject {
    @Published var items: [VendorInventoryItem]

    init(items: [VendorInventoryItem]? = nil) {
        self.items = items ?? VendorMockData.inventory
    }

    var inStockCount: Int {
        items.filter(\.inStock).count
    }

    func toggleStock(for item: VendorInventoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].inStock.toggle()
        items[index].availableToday = items[index].inStock
    }
}
