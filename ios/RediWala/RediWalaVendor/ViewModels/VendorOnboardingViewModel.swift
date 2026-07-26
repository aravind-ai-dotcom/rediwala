import Combine
import Foundation

@MainActor
final class VendorOnboardingViewModel: ObservableObject {
    @Published var vendorName: String = ""
    @Published var selectedCategory: VendorCategory = .vegetables
    @Published var workingHours: VendorWorkingHours = .defaultHours
    @Published var selectedArea: ChennaiArea = VendorMockData.defaultArea

    var trimmedName: String {
        vendorName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canContinueFromName: Bool {
        !trimmedName.isEmpty
    }

    func buildState() -> VendorOnboardingState {
        VendorOnboardingState(
            hasCompletedOnboarding: true,
            vendorName: trimmedName,
            category: selectedCategory,
            workingHours: workingHours,
            area: selectedArea
        )
    }
}
