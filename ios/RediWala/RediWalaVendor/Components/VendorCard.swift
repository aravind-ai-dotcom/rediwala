import SwiftUI

/// Vendor list card for marketplace browsing.
struct VendorCard: View {
    let name: String
    let distance: String
    let category: String
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
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(distance, systemImage: "location.fill")
                    Text("·")
                    Text(category)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Text(isOpen ? "Open" : "Closed")
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
    VendorCard(name: "Kumar Fresh", distance: "120 m", category: "Vegetables", isOpen: true)
        .padding()
        .background(AppTheme.background)
}
