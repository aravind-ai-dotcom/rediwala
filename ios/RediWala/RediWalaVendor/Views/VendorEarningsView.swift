import SwiftUI

struct VendorEarningsView: View {
    let vendorName: String
    let businessName: String
    let category: VendorCategory

    @StateObject private var viewModel: VendorEarningsViewModel
    @State private var showCollectMoney = false

    private let vendorID = VendorIdentityStore.vendorID

    init(
        vendorName: String = "Vendor",
        businessName: String? = nil,
        category: VendorCategory = .vegetables
    ) {
        self.vendorName = vendorName
        self.businessName = businessName ?? "\(vendorName) \(category.englishTitle)"
        self.category = category
        _viewModel = StateObject(wrappedValue: VendorEarningsViewModel(vendorID: VendorIdentityStore.vendorID))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                Text(LocalizedText.resolve("tab.business", fallback: "Business"))
                    .font(.largeTitle.weight(.bold))
                Text("P&L tied to Today's Offerings")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                PrimaryButton(
                    titleKey: "Collect Money",
                    systemImage: "indianrupeesign.circle.fill",
                    style: .accent,
                    prominent: true
                ) {
                    showCollectMoney = true
                }

                Text("Log a sale when a neighbor pays — GPay / UPI.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .offset(y: -8)

                SummaryCard(
                    titleKey: "earnings.today_total",
                    value: "₹\(viewModel.totalRupees)",
                    systemImage: "indianrupeesign.circle.fill",
                    tint: AppTheme.primary
                )

                Text(LocalizedText.resolve("earnings.today_take_in", fallback: "Today's Take-In"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .offset(y: -8)

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
                    SummaryCard(
                        titleKey: "summary.average_sale",
                        value: "₹\(viewModel.averageSale)",
                        systemImage: "chart.line.uptrend.xyaxis",
                        tint: AppTheme.primary
                    )
                    SummaryCard(
                        titleKey: "summary.top_item",
                        value: viewModel.topSellingItem,
                        systemImage: "star.fill",
                        tint: AppTheme.accent
                    )
                }

                Text(LocalizedText.resolve("earnings.recent", fallback: "Recent"))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 4)

                if viewModel.entries.isEmpty {
                    Text("No sales logged yet. Collect money to start today's ledger.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                } else {
                    ForEach(viewModel.entries) { entry in
                        earningsRow(entry)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $showCollectMoney) {
            VendorCollectMoneyView(
                vendorID: vendorID,
                vendorName: vendorName,
                businessName: businessName
            ) { _ in
                viewModel.refresh()
            }
        }
    }

    private func earningsRow(_ entry: VendorEarningsEntry) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedText.resolve(entry.descriptionKey, fallback: entry.descriptionKey))
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
        if hours <= 0 { return "—" }
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours))"
        }
        return String(format: "%.1f", hours)
    }
}

#Preview {
    VendorEarningsView(vendorName: "Murugan", category: .vegetables)
        .environment(\.locale, Locale(identifier: "en"))
}
