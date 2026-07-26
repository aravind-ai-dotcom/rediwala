import SwiftUI

struct LargeActionButton: View {
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    let systemImage: String
    var tint: Color = AppTheme.primary
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 56, height: 56)
                    .background(tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(titleKey)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitleKey)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .padding(16)
            .frame(minHeight: AppTheme.minTap)
            .background(AppTheme.card)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    LargeActionButton(
        titleKey: "language.english",
        subtitleKey: "onboarding.language.englishSubtitle",
        systemImage: "globe",
        isSelected: true
    ) {}
        .padding()
        .background(AppTheme.background)
        .environment(\.locale, Locale(identifier: "en"))
}
