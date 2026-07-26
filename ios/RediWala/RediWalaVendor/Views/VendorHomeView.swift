import SwiftUI

struct VendorHomeView: View {
    @ObservedObject var viewModel: VendorHomeViewModel
    var onGoLive: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.greeting)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(viewModel.vendorName)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .accessibilityElement(children: .combine)

                StatusCard(title: viewModel.statusTitle, isLive: false)

                PrimaryButton(
                    title: "GO LIVE",
                    systemImage: "antenna.radiowaves.left.and.right",
                    style: .primary,
                    action: onGoLive
                )

                Text("Today's Summary")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 4)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    SummaryCard(
                        title: "Sales",
                        value: "₹\(viewModel.summary.salesRupees)",
                        systemImage: "indianrupeesign.circle.fill"
                    )
                    SummaryCard(
                        title: "Customers",
                        value: "\(viewModel.summary.customers)",
                        systemImage: "person.2.fill",
                        tint: AppTheme.accent
                    )
                    SummaryCard(
                        title: "Hours",
                        value: hoursLabel(viewModel.summary.hours),
                        systemImage: "clock.fill",
                        tint: AppTheme.primary
                    )
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func hoursLabel(_ hours: Double) -> String {
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours))"
        }
        return String(format: "%.1f", hours)
    }
}

#Preview {
    VendorHomeView(viewModel: VendorHomeViewModel(), onGoLive: {})
}
