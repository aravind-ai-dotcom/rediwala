import Combine
import Foundation

@MainActor
final class VendorFlowViewModel: ObservableObject {
    @Published private(set) var step: VendorFlowStep = .splash
    @Published var onboarding = VendorOnboardingViewModel()

    private let onboardingStorageKey = "vendor.onboarding.completed"

    init() {
        if UserDefaults.standard.bool(forKey: onboardingStorageKey),
           let saved = loadSavedOnboarding() {
            onboarding.vendorName = saved.vendorName
            onboarding.selectedCategory = saved.category
            onboarding.workingHours = saved.workingHours
            onboarding.selectedArea = saved.area
        }
    }

    func begin() {
        step = .splash
    }

    func finishSplash(isSignedIn: Bool, profileCompleted: Bool) {
        if isSignedIn {
            step = profileCompleted || UserDefaults.standard.bool(forKey: onboardingStorageKey) ? .main : .language
        } else {
            step = .login
        }
    }

    func didSignIn(profileCompleted: Bool) {
        if profileCompleted {
            UserDefaults.standard.set(true, forKey: onboardingStorageKey)
            step = .main
        } else {
            step = .language
        }
    }

    func didSignOut() {
        step = .login
    }

    func languageSelected() {
        step = .welcome
    }

    func welcomeContinue() {
        step = .vendorName
    }

    func nameContinue() {
        guard onboarding.canContinueFromName else { return }
        step = .businessCategory
    }

    func categoryContinue() {
        step = .workingHours
    }

    func completeOnboarding() {
        let state = onboarding.buildState()
        if let match = DemoAuthCatalog.vendors.first(where: {
            $0.displayName.lowercased().contains(state.vendorName.lowercased()) || state.vendorName.lowercased().contains("murugan")
        })?.vendorId {
            VendorIdentityStore.vendorID = match
        } else {
            VendorIdentityStore.vendorID = VendorIdentityStore.resolveVendorID(displayName: state.vendorName)
        }
        saveOnboarding(state)
        step = .main
    }

    private func saveOnboarding(_ state: VendorOnboardingState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "\(onboardingStorageKey).data")
        }
        UserDefaults.standard.set(true, forKey: onboardingStorageKey)
    }

    private func loadSavedOnboarding() -> VendorOnboardingState? {
        guard let data = UserDefaults.standard.data(forKey: "\(onboardingStorageKey).data") else { return nil }
        return try? JSONDecoder().decode(VendorOnboardingState.self, from: data)
    }
}
