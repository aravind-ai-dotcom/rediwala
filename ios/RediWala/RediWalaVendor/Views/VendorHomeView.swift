import SwiftUI

struct VendorHomeView: View {
    @ObservedObject var viewModel: VendorHomeViewModel
    var onGoLive: () -> Void
    var onSelectTab: (VendorTab) -> Void = { _ in }

    @State private var greetingVisible = false
    @State private var statusVisible = false

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                greetingSection
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? 0 : 8)

                StatusCard(titleKey: viewModel.statusTitleKey, isLive: viewModel.status == .live)
                    .opacity(statusVisible ? 1 : 0)
                    .offset(y: statusVisible ? 0 : 10)

                if viewModel.status == .offline {
                    PrimaryButton(
                        titleKey: "home.go_live",
                        systemImage: "antenna.radiowaves.left.and.right",
                        prominent: true
                    ) {
                        onGoLive()
                    }
                }

                summarySection
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.background,
                    AppTheme.primary.opacity(0.04),
                    AppTheme.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                greetingVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.12)) {
                statusVisible = true
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.greetingWithAccent)
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(viewModel.vendorName)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("home.ready_prompt")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(titleKey: "home.summary.title")

            LazyVGrid(columns: summaryColumns, spacing: 12) {
                SummaryCard(
                    titleKey: "summary.sales",
                    value: "₹\(viewModel.summary.salesRupees)",
                    systemImage: "indianrupeesign.circle.fill",
                    compact: true
                )
                SummaryCard(
                    titleKey: "summary.customers",
                    value: "\(viewModel.summary.customers)",
                    systemImage: "person.2.fill",
                    tint: AppTheme.accent,
                    compact: true
                )
                SummaryCard(
                    titleKey: "summary.hours",
                    value: hoursLabel(viewModel.summary.hours),
                    systemImage: "clock.fill",
                    tint: AppTheme.info,
                    compact: true
                )
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(titleKey: "home.quick_actions")

            VStack(spacing: 12) {
                LargeActionButton(
                    titleKey: "tab.inventory",
                    systemImage: "shippingbox.fill",
                    tint: AppTheme.accent
                ) {
                    onSelectTab(.inventory)
                }

                LargeActionButton(
                    titleKey: "tab.earnings",
                    systemImage: "chart.line.uptrend.xyaxis",
                    tint: AppTheme.primary
                ) {
                    onSelectTab(.earnings)
                }

                LargeActionButton(
                    titleKey: "tab.profile",
                    systemImage: "person.fill",
                    tint: AppTheme.info
                ) {
                    onSelectTab(.profile)
                }
            }
        }
    }

    private func hoursLabel(_ hours: Double) -> String {
        String(format: "%.1f", hours)
    }
}

#Preview("Offline") {
    VendorHomeView(viewModel: VendorHomeViewModel(), onGoLive: {})
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Live") {
    VendorHomeView(
        viewModel: {
            let model = VendorHomeViewModel()
            model.status = .live
            return model
        }(),
        onGoLive: {}
    )
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Dark") {
    VendorHomeView(viewModel: VendorHomeViewModel(), onGoLive: {})
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
