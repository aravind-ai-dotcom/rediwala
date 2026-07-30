import Combine
import CoreLocation
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
            geo.selectPilotNeighborhood(selectedNeighborhood, recenter: true)
            mapViewModel.selectNeighborhood(selectedNeighborhood, recenter: true)
            Task { await load() }
        }
    }
    @Published var browseMode: BrowseMode = .list
    @Published var sellers: [Seller] = []
    @Published var isLoading = false
    @Published var showNeedsEditor = false
    @Published private(set) var demandSnapshot: NeighborhoodDemandSnapshot?
    @Published private(set) var opportunities: [OpportunityInsight] = []

    let repository: FirebaseSellerRepository
    let mapViewModel: CustomerMapViewModel
    let needsStore = CustomerNeedsStore.shared
    let followStore = CustomerVendorFollowStore.shared
    let geo = GeoContext.shared

    private var cancellables = Set<AnyCancellable>()
    private let opportunityEngine = OpportunityEngine()

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
        let pool = relevantSellersForToday.filter { needCats.contains($0.category) }
        return ranked(pool).prefix(8).map { $0 }
    }

    var nearbyRightNow: [Seller] {
        relevantSellersForToday
            .filter(\.isEffectivelyLive)
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    var expectedSoon: [Seller] {
        relevantSellersForToday
            .filter { !$0.isEffectivelyLive }
            .sorted { $0.distanceMeters < $1.distanceMeters }
            .prefix(6)
            .map { $0 }
    }

    var myVendors: [Seller] {
        let ids = Set(followStore.myVendorIDs)
        let followed = relevantSellersForToday.filter { ids.contains($0.id) && !followStore.isHidden($0.id) }
        if !followed.isEmpty { return ranked(followed) }
        return Array(nearbyRightNow.prefix(3))
    }

    private var visibleSellers: [Seller] {
        let scope = geo.queryScope()
        return GeoScopedQuery.filter(
            sellers: sellers.filter { !followStore.isHidden($0.id) },
            scope: scope
        )
    }

    private var relevantSellersForToday: [Seller] {
        let needCats = needsStore.matchingCategories
        guard !needCats.isEmpty else { return visibleSellers }
        return visibleSellers.filter { needCats.contains($0.category) }
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
        geo.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func load() async {
        isLoading = true
        let near = geo.neighborhood.asPilotNeighborhood()
        if selectedNeighborhood != near {
            selectedNeighborhood = near
        }
        sellers = await repository.fetchNearbySellers(near: near, scope: geo.queryScope())
        await mapViewModel.load(recenterIfNeeded: false)
        refreshDemandIntelligence()
        isLoading = false
    }

    func openMap() {
        browseMode = .map
        geo.returnToNeighborhood()
        mapViewModel.selectNeighborhood(selectedNeighborhood, recenter: true)
    }

    func returnHomeArea() {
        geo.returnToNeighborhood()
        mapViewModel.recenter()
    }

    private func refreshDemandIntelligence() {
        let liveCategories = nearbyRightNow.map { FirebaseIDMap.firebaseID(for: $0.category) }
        let snapshot = DemandIntelligenceEngine.snapshot(
            for: geo.neighborhood,
            liveVendorCategories: liveCategories,
            activeVendorCount: nearbyRightNow.count
        )
        demandSnapshot = snapshot
        opportunities = opportunityEngine.evaluate(snapshot: snapshot)
    }

    private func ranked(_ pool: [Seller]) -> [Seller] {
        let favorites = repository.favoriteIDs
        let economy = Set(geo.neighborhood.suggestedCategories)

        return pool.sorted { a, b in
            let aScore =
                (a.isEffectivelyLive ? 120 : 0) +
                Int(a.rating * 10) +
                (economy.contains(FirebaseIDMap.firebaseID(for: a.category)) ? 18 : 0) +
                (favorites.contains(a.id) ? 30 : 0) +
                (followStore.myVendorIDs.contains(a.id) ? 20 : 0) +
                max(0, 40 - a.distanceMeters / 50)
            let bScore =
                (b.isEffectivelyLive ? 120 : 0) +
                Int(b.rating * 10) +
                (economy.contains(FirebaseIDMap.firebaseID(for: b.category)) ? 18 : 0) +
                (favorites.contains(b.id) ? 30 : 0) +
                (followStore.myVendorIDs.contains(b.id) ? 20 : 0) +
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
