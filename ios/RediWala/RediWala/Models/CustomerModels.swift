import Foundation

struct MarketCategory: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
}

struct NearbyVendor: Identifiable, Equatable {
    let id: String
    let name: String
    let distance: String
    let category: String
    let isOpen: Bool
}
