import Combine
import Foundation

@MainActor
final class CustomerHomeViewModel: ObservableObject {
    enum BrowseMode: String, CaseIterable, Identifiable {
        case list
        case map

        var id: String { rawValue }

        var titleKey: String {
            switch self {
            case .list: return "home.mode.dashboard"
            case .map: return "home.mode.map"
            }
        }

        var systemImage: String {
            switch self {
            case .list: return "house.fill"
            case .map: return "map.fill"
            }
        }
    }

    @Published var selectedNeighborhood: PilotNeighborhood = CustomerNeighborhoodStore.shared.homeNeighborhood {
        didSet {
            CustomerNeighborhoodStore.shared.select(selectedNeighborhood)
            mapViewModel.selectNeighborhood(selectedNeighborhood, recenter: true)
            Task { await load() }
        }
    }
    @Published var browseMode: BrowseMode = .list
    @Published var sellers: [Seller] = []
    @Published var isLoading = false
    @Published var showNeedsEditor = false

    let repository: FirebaseSellerRepository
    let mapViewModel: CustomerMapViewModel
    let needsStore = CustomerNeedsStore.shared
    let followStore = CustomerVendorFollowStore.shared

    private var cancellables = Set<AnyCancellable>()

    var greetingKey: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "greeting.morning"
        case 12..<17: return "greeting.afternoon"
        default: return "greeting.evening"
        }
    }

    /// Vendors matching today's active needs, prioritized for Home.
    var bestMatches: [Seller] {
        let needCats = needsStore.matchingCategories
        guard !needCats.isEmpty else { return [] }
        let pool = visibleSellers.filter { needCats.contains($0.category) }
        return ranked(pool).prefix(8).map { $0 }
    }

    var nearbyRightNow: [Seller] {
        visibleSellers
            .filter(\.isEffectivelyLive)
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    var expectedSoon: [Seller] {
        visibleSellers
            .filter { !$0.isEffectivelyLive }
            .sorted { $0.distanceMeters < $1.distanceMeters }
            .prefix(6)
            .map { $0 }
    }

    var myVendors: [Seller] {
        let ids = Set(followStore.myVendorIDs)
        let followed = sellers.filter { ids.contains($0.id) && !followStore.isHidden($0.id) }
        if !followed.isEmpty { return ranked(followed) }
        return Array(nearbyRightNow.prefix(3))
    }

    private var visibleSellers: [Seller] {
        sellers.filter {
            $0.neighborhood == selectedNeighborhood && !followStore.isHidden($0.id)
        }
    }

    init(repository: FirebaseSellerRepository) {
        self.repository = repository
        self.mapViewModel = CustomerMapViewModel(
            repository: repository,
            neighborhood: CustomerNeighborhoodStore.shared.homeNeighborhood
        )
        seedDefaultFollowsIfNeeded()

        repository.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        needsStore.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        followStore.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        mapViewModel.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func load() async {
        isLoading = true
        sellers = await repository.fetchNearbySellers(near: selectedNeighborhood)
        await mapViewModel.load(recenterIfNeeded: false)
        isLoading = false
    }

    func openMap() {
        browseMode = .map
        mapViewModel.selectNeighborhood(selectedNeighborhood, recenter: true)
    }

    func returnHomeArea() {
        mapViewModel.recenter()
    }

    private func ranked(_ pool: [Seller]) -> [Seller] {
        let favorites = repository.favoriteIDs
        let weekday = Calendar.current.component(.weekday, from: Date())
        let bias: Set<SellerCategory> = {
            switch weekday {
            case 1, 7: return [.flowers, .iceCream, .kulfi, .juices]
            case 2, 4: return [.milk, .bakery]
            default: return [.vegetables, .fish, .knifeSharpening]
            }
        }()

        return pool.sorted { a, b in
            let aScore =
                (a.isEffectivelyLive ? 120 : 0) +
                Int(a.rating * 10) +
                (bias.contains(a.category) ? 12 : 0) +
                (favorites.contains(a.id) ? 30 : 0) +
                max(0, 40 - a.distanceMeters / 50)
            let bScore =
                (b.isEffectivelyLive ? 120 : 0) +
                Int(b.rating * 10) +
                (bias.contains(b.category) ? 12 : 0) +
                (favorites.contains(b.id) ? 30 : 0) +
                max(0, 40 - b.distanceMeters / 50)
            if aScore != bScore { return aScore > bScore }
            return a.distanceMeters < b.distanceMeters
        }
    }

    private func seedDefaultFollowsIfNeeded() {
        guard followStore.myVendorIDs.isEmpty else { return }
        followStore.track("murugan")
        followStore.track("lakshmi")
        followStore.follow("veg_tNagar_0")
    }
}
