import SwiftUI

struct CustomerRootView: View {
    @EnvironmentObject private var favorites: FavoritesViewModel
    @StateObject private var homeViewModel: CustomerHomeViewModel
    @State private var selectedTab: CustomerTab = .home

    init(repository: LocalSellerRepository) {
        _homeViewModel = StateObject(wrappedValue: CustomerHomeViewModel(repository: repository))
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                NavigationStack {
                    CustomerHomeView(viewModel: homeViewModel)
                }
            case .favorites:
                NavigationStack {
                    FavoritesView()
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
    }
}

#Preview {
    let repo = LocalSellerRepository()
    return CustomerRootView(repository: repo)
        .environmentObject(FavoritesViewModel(repository: repo))
        .environmentObject(AppLanguageStore())
        .environment(\.locale, Locale(identifier: "en"))
}
