import SwiftUI

struct VendorRootView: View {
    @StateObject private var homeViewModel = VendorHomeViewModel()
    @State private var selectedTab: VendorTab = .home
    @State private var isShowingLive = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    VendorHomeView(viewModel: homeViewModel) {
                        isShowingLive = true
                    }
                case .inventory:
                    VendorPlaceholderTabView(title: "Inventory", systemImage: "basket.fill")
                case .earnings:
                    VendorPlaceholderTabView(title: "Earnings", systemImage: "indianrupeesign.circle.fill")
                case .profile:
                    VendorProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavigationBar(selected: $selectedTab)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $isShowingLive) {
            VendorLiveView(homeViewModel: homeViewModel) {
                homeViewModel.stopLive()
                isShowingLive = false
            }
        }
    }
}

#Preview {
    VendorRootView()
}
