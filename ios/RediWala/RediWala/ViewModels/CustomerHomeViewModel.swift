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
            case .list: return "home.mode.list"
            case .map: return "home.mode.map"
            }
        }

        var systemImage: String {
            switch self {
            case .list: return "list.bullet"
            case .map: return "map.fill"
            }
        }
    }

    @Published var selectedNeighborhood: PilotNeighborhood = .tNagar {
        didSet {
            mapViewModel.selectNeighborhood(selectedNeighborhood)
        }
    }
    @Published var browseMode: BrowseMode = .list
    @Published var sellers: [Seller] = []
    @Published var isLoading = false
    @Published private(set) var categoriesByGroup: [(group: CategoryGroup, categories: [MarketCategory])] = []

    let repository: LocalSellerRepository
    let mapViewModel: CustomerMapViewModel

    private var cancellables = Set<AnyCancellable>()

    var greetingKey: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "greeting.morning"
        case 12..<17: return "greeting.afternoon"
        default: return "greeting.evening"
        }
    }

    var vendors: [Seller] { sellers }
    var currentLocationKey: String { selectedNeighborhood.nameKey }
    var categories: [MarketCategory] {
        categoriesByGroup.flatMap(\.categories)
    }

    init(repository: LocalSellerRepository) {
        self.repository = repository
        self.mapViewModel = CustomerMapViewModel(repository: repository, neighborhood: .tNagar)
        rebuildCategoryGroups()

        repository.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        mapViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func load() async {
        isLoading = true
        sellers = await repository.fetchNearbySellers()
        await mapViewModel.load()
        isLoading = false
    }

    func sellers(for category: SellerCategory) async -> [Seller] {
        await repository.fetchSellers(category: category)
    }

    func vendors(for category: SellerCategory) -> [Seller] {
        sellers.filter { $0.category == category }
    }

    func isFavorite(_ id: String) -> Bool {
        repository.isFavorite(id: id)
    }

    func toggleFavorite(_ id: String) {
        Task {
            await repository.toggleFavorite(id: id)
        }
    }

    private func rebuildCategoryGroups() {
        categoriesByGroup = CategoryGroup.allCases
            .sorted { $0.displayOrder < $1.displayOrder }
            .map { group in
                let cats = SellerCategory.categories(in: group).map(MarketCategory.init)
                return (group, cats)
            }
    }
}
