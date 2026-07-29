import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @StateObject private var flowViewModel = VendorFlowViewModel()
    @StateObject private var firebaseSession = VendorFirebaseSession.shared

    var body: some View {
        Group {
            switch flowViewModel.step {
            case .splash:
                SplashView()
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
            await firebaseSession.bootstrap()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppLanguageStore())
        .environment(\.locale, Locale(identifier: "en"))
}
