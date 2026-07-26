import SwiftUI

struct CustomerRootView: View {
    @EnvironmentObject private var favorites: FavoritesViewModel
    @StateObject private var homeViewModel: CustomerHomeViewModel
    @State private var selectedTab: CustomerTab = .home

    init(repository: LocalSellerRepository) {
        _homeViewModel = StateObject(wrappedValue: CustomerHomeViewModel(repository: repository))
    }

    var body: some View {
        VStack(spacing: 0) {
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

            BottomTabBar(selected: $selectedTab)
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
