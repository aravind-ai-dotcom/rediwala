import SwiftUI

struct SummaryCard: View {
    let titleKey: String
    let value: String
    let systemImage: String
    var tint: Color = AppTheme.primary
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 12) {
            Image(systemName: systemImage)
                .font(compact ? .title3.weight(.semibold) : .title2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: compact ? 36 : 40, height: compact ? 36 : 40)
                .background(
                    LinearGradient(
                        colors: [tint.opacity(0.18), tint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(value)
                .font(compact ? .title2.weight(.bold) : .title.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(LocalizedText.resolve(titleKey, fallback: englishFallback(for: titleKey)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 14 : 16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }

    private func englishFallback(for key: String) -> String {
        switch key {
        case "earnings.today_total": return "Today's Take-In"
        case "summary.customers": return "Customers Served"
        case "summary.hours": return "Hours Worked"
        case "summary.average_sale": return "Average Sale"
        case "summary.top_item": return "Top Selling"
        case "summary.sales": return "Sales"
        default: return key.split(separator: ".").last.map(String.init)?.replacingOccurrences(of: "_", with: " ").capitalized ?? key
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        SummaryCard(titleKey: "summary.sales", value: "₹0", systemImage: "indianrupeesign.circle.fill", compact: true)
        SummaryCard(titleKey: "summary.customers", value: "0", systemImage: "person.2.fill", tint: AppTheme.accent, compact: true)
        SummaryCard(titleKey: "summary.hours", value: "0.0", systemImage: "clock.fill", tint: AppTheme.info, compact: true)
    }
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
