import SwiftUI

struct CustomerContentView: View {
    let repository: LocalSellerRepository
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var favoritesViewModel: FavoritesViewModel
    @StateObject private var flowViewModel = CustomerFlowViewModel()

    var body: some View {
        Group {
            switch flowViewModel.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .language:
                LanguageSelectionView(onContinue: flowViewModel.completeLanguageSelection)
                    .transition(.opacity)
            case .welcome:
                WelcomeView(onContinue: flowViewModel.completeWelcome)
                    .transition(.opacity)
            case .locationPermission:
                LocationPermissionView(
                    onContinue: flowViewModel.completeLocationPermission,
                    onSkip: flowViewModel.completeLocationPermission
                )
                .transition(.opacity)
            case .main:
                CustomerRootView(repository: repository)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: flowViewModel.phase)
        .environment(\.locale, languageStore.locale)
        .task(id: flowViewModel.phase) {
            guard flowViewModel.phase == .splash else { return }
            try? await Task.sleep(for: .seconds(1.4))
            flowViewModel.finishSplash()
        }
    }
}

#Preview {
    let repo = LocalSellerRepository()
    return CustomerContentView(repository: repo)
        .environmentObject(AppLanguageStore())
        .environmentObject(FavoritesViewModel(repository: repo))
        .environment(\.locale, Locale(identifier: "en"))
}
