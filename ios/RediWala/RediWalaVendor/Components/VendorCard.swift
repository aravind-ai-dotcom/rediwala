import SwiftUI

struct VendorCard: View {
    let nameKey: String
    let distanceKey: String
    let categoryKey: String
    let isOpen: Bool

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
                Text(LocalizedStringKey(nameKey))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 8) {
                    Label {
                        Text(LocalizedStringKey(distanceKey))
                    } icon: {
                        Image(systemName: "location.fill")
                    }
                    Text("·")
                    Text(LocalizedStringKey(categoryKey))
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

                Text(LocalizedStringKey(isOpen ? "vendor.open" : "vendor.closed"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isOpen ? AppTheme.primary : AppTheme.danger)
            }

            Spacer(minLength: 0)
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
        nameKey: "vendor.name.murugan",
        distanceKey: "distance.near_pondy",
        categoryKey: "category.vegetables",
        isOpen: true
    )
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
