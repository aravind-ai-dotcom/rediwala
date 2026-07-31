import SwiftUI

struct VendorRootView: View {
    let onboardingState: VendorOnboardingState
    @EnvironmentObject private var languageStore: AppLanguageStore

    @StateObject private var homeViewModel: VendorHomeViewModel
    @StateObject private var profileViewModel: VendorProfileViewModel
    @StateObject private var liveSessionViewModel: VendorLiveSessionViewModel
    @State private var selectedTab: VendorTab = .home

    init(onboardingState: VendorOnboardingState) {
        self.onboardingState = onboardingState
        let vendorID = VendorIdentityStore.vendorID
        _homeViewModel = StateObject(wrappedValue: VendorHomeViewModel(
            vendorName: onboardingState.vendorName,
            area: onboardingState.area
        ))
        _profileViewModel = StateObject(wrappedValue: VendorProfileViewModel(onboarding: onboardingState, vendorID: vendorID))
        _liveSessionViewModel = StateObject(wrappedValue: VendorLiveSessionViewModel(
            vendorId: vendorID,
            category: onboardingState.category
        ))
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                VendorHomeView(
                    viewModel: homeViewModel,
                    liveSession: liveSessionViewModel,
                    onSelectTab: { selectedTab = $0 }
                )
            case .map:
                VendorWorkingMapView(liveSession: liveSessionViewModel, showsCloseButton: false)
            case .messages:
                VendorMessagesView(liveSession: liveSessionViewModel)
            case .earnings:
                VendorEarningsView(
                    vendorName: onboardingState.vendorName,
                    businessName: "\(onboardingState.vendorName) \(onboardingState.category.englishTitle)",
                    category: onboardingState.category
                )
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
        .onAppear {
            homeViewModel.applyOnboarding(onboardingState)
            liveSessionViewModel.applyVendorCategory(onboardingState.category)
            liveSessionViewModel.updateOperatingArea(onboardingState.area)
            liveSessionViewModel.setProfilePhotoPath(profileViewModel.profile.photoLocalPath)
            liveSessionViewModel.seedOperatingHours(
                openMinutes: onboardingState.workingHours.startMinutes,
                closeMinutes: onboardingState.workingHours.endMinutes
            )
        }
        .onChange(of: profileViewModel.profile.photoLocalPath) { _, newPath in
            liveSessionViewModel.setProfilePhotoPath(newPath)
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
