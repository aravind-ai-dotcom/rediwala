import Combine
import Foundation

/// Persists the customer's home neighborhood — the anchor for discovery and maps.
@MainActor
final class CustomerNeighborhoodStore: ObservableObject {
    static let shared = CustomerNeighborhoodStore()

    @Published var homeNeighborhood: PilotNeighborhood {
        didSet { persist() }
    }

    private let key = "customer.home_neighborhood.v1"

    /// Neighborhoods offered during first-run setup (calm short list).
    static let onboardingChoices: [PilotNeighborhood] = [
        .westMambalam,
        .thiruvanmiyur,
        .adyar,
        .velachery,
        .ashokNagar,
        .tNagar,
        .besantNagar,
        .annaNagar
    ]

    private init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let restored = PilotNeighborhood(rawValue: raw) {
            homeNeighborhood = restored
        } else {
            homeNeighborhood = .westMambalam
        }
    }

    func select(_ neighborhood: PilotNeighborhood) {
        homeNeighborhood = neighborhood
    }

    /// Used by GeoContext to mirror state without recursive geo updates.
    func applyFromGeoContext(_ neighborhood: PilotNeighborhood) {
        guard homeNeighborhood != neighborhood else { return }
        homeNeighborhood = neighborhood
    }

    private func persist() {
        UserDefaults.standard.set(homeNeighborhood.rawValue, forKey: key)
    }
}

enum CustomerOnboardingStore {
    private static let completedKey = "customer.onboarding.completed.v1"
    private static let languageChosenKey = "customer.onboarding.language_chosen.v1"

    static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    static var hasChosenLanguage: Bool {
        UserDefaults.standard.bool(forKey: languageChosenKey)
            || UserDefaults.standard.string(forKey: "customer.app.language") != nil
    }

    static func markLanguageChosen() {
        UserDefaults.standard.set(true, forKey: languageChosenKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }
}
