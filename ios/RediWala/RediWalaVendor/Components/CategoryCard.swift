import SwiftUI

struct CategoryCard: View {
    let title: String
    let systemImage: String
    var tint: Color = AppTheme.primary

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 56, height: 56)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        CategoryCard(title: "Vegetables", systemImage: "leaf.fill")
        CategoryCard(title: "Fruits", systemImage: "carrot.fill", tint: AppTheme.accent)
        CategoryCard(title: "Milk", systemImage: "cup.and.saucer.fill")
    }
    .padding()
    .background(AppTheme.background)
}
