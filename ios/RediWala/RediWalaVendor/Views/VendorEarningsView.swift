import SwiftUI

struct VendorEarningsView: View {
    @StateObject private var viewModel = VendorEarningsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                SectionHeader(
                    titleKey: "tab.business",
                    subtitleKey: "earnings.subtitle"
                )

                SummaryCard(
                    titleKey: "earnings.today_total",
                    value: "₹\(viewModel.totalRupees)",
                    systemImage: "indianrupeesign.circle.fill",
                    tint: AppTheme.primary
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    SummaryCard(
                        titleKey: "summary.customers",
                        value: "\(viewModel.summary.customers)",
                        systemImage: "person.2.fill",
                        tint: AppTheme.accent
                    )
                    SummaryCard(
                        titleKey: "summary.hours",
                        value: hoursLabel(viewModel.summary.hours),
                        systemImage: "clock.fill",
                        tint: AppTheme.info
                    )
                }

                Text("earnings.recent")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 4)

                ForEach(viewModel.entries) { entry in
                    earningsRow(entry)
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func earningsRow(_ entry: VendorEarningsEntry) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(entry.descriptionKey))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(entry.timeLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Text("₹\(entry.amountRupees)")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primary)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func hoursLabel(_ hours: Double) -> String {
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours))"
        }
        return String(format: "%.1f", hours)
    }
}

#Preview {
    VendorEarningsView()
        .environment(\.locale, Locale(identifier: "en"))
}
