import SwiftUI

struct CategoryCard: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    var tint: Color = AppTheme.primary
    var isComingSoon: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(isComingSoon ? AppTheme.textSecondary : tint)
                .frame(width: 52, height: 52)
                .background((isComingSoon ? AppTheme.textSecondary : tint).opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(titleKey)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)

            if isComingSoon {
                Text("category.coming_soon")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .opacity(isComingSoon ? 0.72 : 1)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isComingSoon ? [] : .isButton)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        CategoryCard(titleKey: "category.vegetables", systemImage: "leaf.fill")
        CategoryCard(titleKey: "category.tailor", systemImage: "scissors", isComingSoon: true)
        CategoryCard(titleKey: "category.kulfi", systemImage: "snowflake", tint: AppTheme.accent)
    }
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
