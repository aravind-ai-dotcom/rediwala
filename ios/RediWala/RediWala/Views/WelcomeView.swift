import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    private let features: [(LocalizedStringKey, LocalizedStringKey, String, Color)] = [
        ("onboarding.welcome.feature1.title", "onboarding.welcome.feature1.subtitle", "storefront.fill", AppTheme.primary),
        ("onboarding.welcome.feature2.title", "onboarding.welcome.feature2.subtitle", "leaf.fill", AppTheme.accent),
        ("onboarding.welcome.feature3.title", "onboarding.welcome.feature3.subtitle", "mappin.and.ellipse", AppTheme.info)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("🛺")
                        .font(.system(size: 56))
                        .accessibilityHidden(true)

                    Text("onboarding.welcome.title")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("onboarding.welcome.subtitle")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: feature.2)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(feature.3)
                                    .frame(width: 44, height: 44)
                                    .background(feature.3.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.0)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Text(feature.1)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(titleKey: "onboarding.welcome.continue", systemImage: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    WelcomeView(onContinue: {})
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Small Dynamic Type") {
    WelcomeView(onContinue: {})
        .environment(\.dynamicTypeSize, .accessibility2)
        .environment(\.locale, Locale(identifier: "ta"))
}
