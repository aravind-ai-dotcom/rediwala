import SwiftUI

struct LargeActionButton: View {
    let titleKey: String
    var subtitleKey: String? = nil
    var systemImage: String
    var tint: Color = AppTheme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: AppTheme.minTap, height: AppTheme.minTap)
                    .background(tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if let subtitleKey {
                        Text(LocalizedStringKey(subtitleKey))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(16)
            .frame(minHeight: AppTheme.minTap)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(ScalePressButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ScrollView {
        LargeActionButton(
            titleKey: "settings.title",
            subtitleKey: "settings.subtitle",
            systemImage: "gearshape.fill"
        ) {}
        .padding()
    }
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
