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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
    }
}

#Preview {
    SummaryCard(title: "Nearby", value: "12", systemImage: "mappin.and.ellipse")
        .padding()
        .background(AppTheme.background)
}
