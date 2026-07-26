import SwiftUI

struct LocationPermissionView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    private let benefits: [LocalizedStringKey] = [
        "onboarding.location.benefit1",
        "onboarding.location.benefit2",
        "onboarding.location.benefit3"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(AppTheme.info)
                    .symbolEffect(.pulse)
                    .accessibilityHidden(true)
                    .padding(.top, 12)

                VStack(spacing: 12) {
                    Text("onboarding.location.title")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("onboarding.location.subtitle")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(benefits.enumerated()), id: \.offset) { _, benefitKey in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.primary)

                            Text(benefitKey)
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                PrimaryButton(titleKey: "onboarding.location.continue", systemImage: "location.fill") {
                    onContinue()
                }

                Button(action: onSkip) {
                    Text("onboarding.location.skip")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.minTap)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    LocationPermissionView(onContinue: {}, onSkip: {})
        .environment(\.locale, Locale(identifier: "en"))
}
