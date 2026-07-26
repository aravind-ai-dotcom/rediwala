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
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            advanceFromSplash()
        }
    }

    func advanceFromSplash() {
        step = UserDefaults.standard.bool(forKey: onboardingStorageKey) ? .main : .language
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
        saveOnboarding(state)
        step = .main
    }

    func resetOnboardingForPreview() {
        UserDefaults.standard.removeObject(forKey: onboardingStorageKey)
        step = .language
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
