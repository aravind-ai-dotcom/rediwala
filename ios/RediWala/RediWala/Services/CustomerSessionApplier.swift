import Foundation

/// Applies RTDB customer persona data into local preference stores, and clears on sign-out.
@MainActor
enum CustomerSessionApplier {
    static func apply(profile: DemoUserProfile) async {
        if let language = AppLanguage(rawValue: profile.preferredLanguage) {
            // Language store is environment-owned; persist raw preference for restore.
            UserDefaults.standard.set(language.rawValue, forKey: "customer.app.language")
        }

        guard let customer = try? await DemoUserProfileService.shared.fetchCustomerProfile(uid: profile.uid) else {
            return
        }

        if let language = customer.preferredLanguage.flatMap(AppLanguage.init(rawValue:)) {
            UserDefaults.standard.set(language.rawValue, forKey: "customer.app.language")
        }

        let neighborhood = mapNeighborhood(customer.homeNeighborhood)
        CustomerNeighborhoodStore.shared.select(neighborhood)

        CustomerNeedsStore.shared.replaceToday(
            with: customer.todaysNeeds.compactMap(CustomerNeedItem.init(rawValue:))
        )
        CustomerVendorFollowStore.shared.replaceFollows(
            followed: customer.followedVendorIds,
            saved: customer.savedVendorIds
        )

        if !customer.apartmentMetadata.isEmpty {
            UserDefaults.standard.set(customer.apartmentMetadata, forKey: "customer.apartment.metadata.v1")
        } else {
            UserDefaults.standard.removeObject(forKey: "customer.apartment.metadata.v1")
        }

        CustomerOnboardingStore.markLanguageChosen()
        CustomerOnboardingStore.markCompleted()
    }

    static func clear() {
        CustomerNeedsStore.shared.clearToday()
        CustomerVendorFollowStore.shared.clearAll()
        UserDefaults.standard.removeObject(forKey: "customer.apartment.metadata.v1")
        UserDefaults.standard.removeObject(forKey: "customer.todays_needs.v2")
        UserDefaults.standard.removeObject(forKey: "customer.todays_needs.completed.v2")
        UserDefaults.standard.removeObject(forKey: "customer.vendor_follows.v1")
    }

    private static func mapNeighborhood(_ raw: String) -> PilotNeighborhood {
        switch raw {
        case "west_mambalam", "westMambalam": return .westMambalam
        case "thiruvanmiyur": return .thiruvanmiyur
        case "t_nagar", "tNagar": return .tNagar
        case "adyar": return .adyar
        case "velachery": return .velachery
        case "besant_nagar", "besantNagar": return .besantNagar
        case "anna_nagar", "annaNagar": return .annaNagar
        default: return .westMambalam
        }
    }
}
