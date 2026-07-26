import Combine
import Foundation

@MainActor
final class VendorProfileViewModel: ObservableObject {
    @Published var profile: VendorProfile
    @Published var isShowingSettings = false

    init(onboarding: VendorOnboardingState? = nil, languageKey: String? = nil) {
        let resolvedLanguageKey = languageKey ?? AppLanguage.english.profileLabelKey
        if let onboarding {
            let hoursFormatter = DateFormatter()
            hoursFormatter.timeStyle = .short
            profile = VendorProfile(
                name: onboarding.vendorName,
                languageKey: resolvedLanguageKey,
                phone: VendorMockData.defaultPhone,
                categoryKey: onboarding.category.titleKey,
                workingHours: onboarding.workingHours.formatted(using: hoursFormatter),
                areaKey: onboarding.area.labelKey
            )
        } else {
            let hoursFormatter = DateFormatter()
            hoursFormatter.timeStyle = .short
            profile = VendorProfile(
                name: String(localized: String.LocalizationValue(VendorMockData.defaultVendorName)),
                languageKey: resolvedLanguageKey,
                phone: VendorMockData.defaultPhone,
                categoryKey: VendorCategory.vegetables.titleKey,
                workingHours: VendorWorkingHours.defaultHours.formatted(using: hoursFormatter),
                areaKey: ChennaiArea.tNagar.labelKey
            )
        }
    }

    func updateLanguageKey(_ key: String) {
        profile.languageKey = key
    }
}
