import SwiftUI

struct CustomerRootView: View {
    @EnvironmentObject private var favorites: FavoritesViewModel
    @StateObject private var homeViewModel: CustomerHomeViewModel
    @State private var selectedTab: CustomerTab = .home

    init(repository: FirebaseSellerRepository) {
        _homeViewModel = StateObject(wrappedValue: CustomerHomeViewModel(repository: repository))
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                NavigationStack {
                    CustomerHomeView(viewModel: homeViewModel, showsMapInline: false)
                }
            case .map:
                NavigationStack {
                    CustomerMapView(
                        viewModel: homeViewModel.mapViewModel,
                        favorites: favorites,
                        followStore: homeViewModel.followStore,
                        needsStore: homeViewModel.needsStore,
                        onShowList: { selectedTab = .home },
                        onReturnHome: { homeViewModel.returnHomeArea() }
                    )
                }
            case .messages:
                NavigationStack {
                    CustomerMessagesView()
                }
            case .watchlist:
                NavigationStack {
                    CustomerWatchListView(viewModel: homeViewModel)
                }
            case .profile:
                NavigationStack {
                    ProfileView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomTabBar(selected: $selectedTab)
                .background(AppTheme.card.ignoresSafeArea(edges: .bottom))
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task { await homeViewModel.load() }
    }
}

#Preview {
    let repo = FirebaseSellerRepository()
    return CustomerRootView(repository: repo)
        .environmentObject(FavoritesViewModel(repository: repo))
        .environmentObject(AppLanguageStore())
        .environment(\.locale, Locale(identifier: "en"))
}
