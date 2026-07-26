import SwiftUI

struct VendorRootView: View {
    let onboardingState: VendorOnboardingState
    @EnvironmentObject private var languageStore: AppLanguageStore

    @StateObject private var homeViewModel: VendorHomeViewModel
    @StateObject private var profileViewModel: VendorProfileViewModel
    @State private var selectedTab: VendorTab = .home
    @State private var isShowingLive = false

    init(onboardingState: VendorOnboardingState) {
        self.onboardingState = onboardingState
        _homeViewModel = StateObject(wrappedValue: VendorHomeViewModel(
            vendorName: onboardingState.vendorName,
            area: onboardingState.area
        ))
        _profileViewModel = StateObject(wrappedValue: VendorProfileViewModel(onboarding: onboardingState))
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                VendorHomeView(
                    viewModel: homeViewModel,
                    onGoLive: { isShowingLive = true },
                    onSelectTab: { selectedTab = $0 }
                )
            case .inventory:
                VendorInventoryView()
            case .earnings:
                VendorEarningsView()
            case .profile:
                VendorProfileView(viewModel: profileViewModel)
                    .onAppear {
                        profileViewModel.updateLanguageKey(languageStore.selected.profileLabelKey)
                    }
                    .onChange(of: languageStore.selected) { _, newValue in
                        profileViewModel.updateLanguageKey(newValue.profileLabelKey)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomTabBar(selected: $selectedTab)
                .background(AppTheme.card.ignoresSafeArea(edges: .bottom))
        }
        .background(AppTheme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $isShowingLive) {
            VendorLiveView(homeViewModel: homeViewModel) {
                homeViewModel.stopLive()
                isShowingLive = false
            }
        }
        .onAppear {
            homeViewModel.applyOnboarding(onboardingState)
        }
    }
}

#Preview {
    VendorRootView(onboardingState: VendorOnboardingState(
        hasCompletedOnboarding: true,
        vendorName: "Murugan",
        category: .vegetables,
        workingHours: .defaultHours,
        area: .tNagar
    ))
    .environmentObject(AppLanguageStore())
    .environment(\.locale, Locale(identifier: "en"))
}
