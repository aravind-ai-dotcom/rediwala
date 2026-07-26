import SwiftUI

struct CategoryCard: View {
    let titleKey: String
    let systemImage: String
    var tint: Color = AppTheme.primary
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 56, height: 56)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(LocalizedStringKey(titleKey))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppTheme.card)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(isSelected ? 0.08 : 0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        CategoryCard(titleKey: "category.vegetables", systemImage: "leaf.fill", isSelected: true)
        CategoryCard(titleKey: "category.fruits", systemImage: "carrot.fill", tint: AppTheme.accent)
        CategoryCard(titleKey: "category.milk", systemImage: "cup.and.saucer.fill", tint: AppTheme.info)
    }
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
