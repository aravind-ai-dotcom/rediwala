import SwiftUI

struct CustomerContentView: View {
    @ObservedObject var repository: FirebaseSellerRepository
    @ObservedObject var authService: FirebaseAuthService
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var favoritesViewModel: FavoritesViewModel
    @StateObject private var flowViewModel = CustomerFlowViewModel()
    @State private var didBootstrap = false
    @State private var didFinishSplashAuth = false

    var body: some View {
        Group {
            switch flowViewModel.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .login:
                CustomerLoginView(authService: authService)
                    .transition(.opacity)
            case .language:
                LanguageSelectionView(onContinue: flowViewModel.completeLanguageSelection)
                    .transition(.opacity)
            case .welcome:
                WelcomeView(onContinue: flowViewModel.completeWelcome)
                    .transition(.opacity)
            case .neighborhood:
                NeighborhoodSelectionView(onContinue: { flowViewModel.completeNeighborhoodSelection() })
                    .transition(.opacity)
            case .main:
                CustomerRootView(repository: repository)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: flowViewModel.phase)
        .environment(\.locale, languageStore.locale)
        .task {
            guard !didFinishSplashAuth else { return }
            try? await Task.sleep(for: .seconds(1.2))
            await authService.restoreSessionIfNeeded()
            if let language = authService.userProfile?.preferredLanguage,
               let appLanguage = AppLanguage(rawValue: language) {
                languageStore.language = appLanguage
            }
            didFinishSplashAuth = true
            flowViewModel.finishSplash(
                isSignedIn: authService.isSignedIn,
                profileCompleted: authService.userProfile?.profileCompleted ?? false
            )
        }
        .onChange(of: authService.state) { _, newValue in
            if case .signedIn = newValue, flowViewModel.phase == .login {
                if let language = authService.userProfile?.preferredLanguage,
                   let appLanguage = AppLanguage(rawValue: language) {
                    languageStore.language = appLanguage
                }
                flowViewModel.didSignIn(profileCompleted: authService.userProfile?.profileCompleted ?? true)
            }
            if case .signedOut = newValue, flowViewModel.phase == .main {
                didBootstrap = false
                repository.shutdown()
                flowViewModel.didSignOut()
            }
        }
        .task(id: flowViewModel.phase) {
            guard flowViewModel.phase == .main else { return }
            guard !didBootstrap else { return }
            didBootstrap = true
            if let uid = authService.currentUID {
                await repository.bootstrap(customerID: uid, language: languageStore.language)
            }
        }
        .onDisappear {
            repository.shutdown()
        }
    }
}

#Preview {
    let repo = FirebaseSellerRepository()
    return CustomerContentView(repository: repo, authService: FirebaseAuthService())
        .environmentObject(AppLanguageStore())
        .environmentObject(FavoritesViewModel(repository: repo))
        .environment(\.locale, Locale(identifier: "en"))
}
