import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                Text("🛺")
                    .font(.system(size: 80))
                    .accessibilityHidden(true)

                SectionHeader(
                    titleKey: "welcome.title",
                    subtitleKey: "welcome.subtitle"
                )

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "location.fill", key: "welcome.feature.location")
                    featureRow(icon: "antenna.radiowaves.left.and.right", key: "welcome.feature.live")
                    featureRow(icon: "indianrupeesign.circle.fill", key: "welcome.feature.earnings")
                }
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(titleKey: "welcome.get_started", systemImage: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func featureRow(icon: String, key: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 44, height: 44)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(LocalizedStringKey(key))
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WelcomeView(onContinue: {})
        .environment(\.locale, Locale(identifier: "en"))
}
