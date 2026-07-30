import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @StateObject private var flowViewModel = VendorFlowViewModel()
    @StateObject private var firebaseSession = VendorFirebaseSession.shared
    @State private var didFinishSplashAuth = false

    var body: some View {
        Group {
            switch flowViewModel.step {
            case .splash:
                SplashView()
            case .login:
                VendorLoginView(firebaseSession: firebaseSession)
            case .language:
                LanguageSelectionView {
                    flowViewModel.languageSelected()
                }
            case .welcome:
                WelcomeView {
                    flowViewModel.welcomeContinue()
                }
            case .vendorName:
                VendorNameView(viewModel: flowViewModel.onboarding) {
                    flowViewModel.nameContinue()
                }
            case .businessCategory:
                BusinessCategoryView(viewModel: flowViewModel.onboarding) {
                    flowViewModel.categoryContinue()
                }
            case .workingHours:
                WorkingHoursView(viewModel: flowViewModel.onboarding) {
                    flowViewModel.completeOnboarding()
                }
            case .main:
                VendorRootView(onboardingState: flowViewModel.onboarding.buildState())
            }
        }
        .environmentObject(firebaseSession)
        .environment(\.locale, languageStore.locale)
        .animation(.easeInOut(duration: 0.25), value: flowViewModel.step)
        .onAppear {
            flowViewModel.begin()
        }
        .task {
            guard !didFinishSplashAuth else { return }
            try? await Task.sleep(for: .seconds(1.2))
            await firebaseSession.bootstrap()
            didFinishSplashAuth = true
            flowViewModel.finishSplash(
                isSignedIn: firebaseSession.isReady,
                profileCompleted: firebaseSession.userProfile?.profileCompleted ?? false
            )
        }
        .onChange(of: firebaseSession.readiness) { _, newValue in
            if case .ready = newValue, flowViewModel.step == .login {
                flowViewModel.didSignIn(profileCompleted: firebaseSession.userProfile?.profileCompleted ?? true)
            }
            if case .signedOut = newValue, flowViewModel.step == .main {
                flowViewModel.didSignOut()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppLanguageStore())
        .environment(\.locale, Locale(identifier: "en"))
}
