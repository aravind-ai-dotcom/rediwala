import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = AppTheme.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack(spacing: 12) {
        SummaryCard(title: "Sales", value: "₹0", systemImage: "indianrupeesign.circle.fill")
        SummaryCard(title: "Customers", value: "0", systemImage: "person.2.fill", tint: AppTheme.accent)
    }
    .padding()
    .background(AppTheme.background)
}
