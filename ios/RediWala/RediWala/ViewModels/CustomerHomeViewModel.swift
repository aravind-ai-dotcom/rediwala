import Combine
import Foundation

@MainActor
final class CustomerHomeViewModel: ObservableObject {
    @Published var currentLocation: String = "Koramangala, Bengaluru"

    @Published var categories: [MarketCategory] = [
        .init(id: "veg", title: "Vegetables", systemImage: "leaf.fill"),
        .init(id: "fruit", title: "Fruits", systemImage: "carrot.fill"),
        .init(id: "flower", title: "Flowers", systemImage: "camera.macro"),
        .init(id: "milk", title: "Milk", systemImage: "cup.and.saucer.fill"),
        .init(id: "fish", title: "Fish", systemImage: "fish.fill"),
        .init(id: "bakery", title: "Bakery", systemImage: "birthday.cake.fill")
    ]

    @Published var vendors: [NearbyVendor] = [
        .init(id: "1", name: "Kumar Fresh", distance: "120 m", category: "Vegetables", isOpen: true),
        .init(id: "2", name: "Anita Fruits", distance: "250 m", category: "Fruits", isOpen: true),
        .init(id: "3", name: "Rose Cart", distance: "400 m", category: "Flowers", isOpen: false),
        .init(id: "4", name: "Daily Dairy", distance: "600 m", category: "Milk", isOpen: true),
        .init(id: "5", name: "Coastal Catch", distance: "800 m", category: "Fish", isOpen: true),
        .init(id: "6", name: "Warm Loaf", distance: "1.1 km", category: "Bakery", isOpen: false)
    ]
}
