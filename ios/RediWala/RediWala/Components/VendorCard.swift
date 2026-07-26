import SwiftUI

struct VendorCard: View {
    let name: String
    let distance: String
    let categoryKey: LocalizedStringKey
    let isOpen: Bool
    var rating: Double? = nil

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.primary.opacity(0.12))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "storefront.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.primary)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Label(distance, systemImage: "location.fill")
                    Text("·")
                    Text(categoryKey)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Text(isOpen ? "vendor.open" : "vendor.closed")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isOpen ? AppTheme.primary : AppTheme.danger)

                    if let rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                            Text(String(format: "%.1f", rating))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    } else {
                        Text("vendor.ratingPlaceholder")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VendorCard(
        name: "Murugan",
        distance: "120 m",
        categoryKey: "category.vegetables",
        isOpen: true,
        rating: 4.6
    )
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
