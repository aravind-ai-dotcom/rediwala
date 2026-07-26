import SwiftUI

struct VendorLiveView: View {
    @ObservedObject var homeViewModel: VendorHomeViewModel
    @StateObject private var liveViewModel: VendorLiveViewModel
    var onStop: () -> Void

    init(homeViewModel: VendorHomeViewModel, onStop: @escaping () -> Void) {
        self.homeViewModel = homeViewModel
        self.onStop = onStop
        _liveViewModel = StateObject(wrappedValue: VendorLiveViewModel(area: homeViewModel.area))
    }

    var body: some View {
        VStack(spacing: AppTheme.sectionSpacing) {
            StatusCard(titleKey: "status.live", isLive: true)

            VStack(spacing: 12) {
                liveStatRow(icon: "location.fill", titleKey: "live.location", value: liveViewModel.locationLabel)
                liveStatRow(icon: "clock.fill", titleKey: "live.start_time", value: liveViewModel.startTimeLabel)
                liveStatRow(
                    icon: "person.2.fill",
                    titleKey: "live.customers_today",
                    value: "\(liveViewModel.customersToday)"
                )
            }

            Spacer(minLength: 0)

            PrimaryButton(
                titleKey: "live.stop",
                systemImage: "stop.fill",
                style: .danger,
                action: onStop
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            homeViewModel.goLive()
            liveViewModel.beginSession()
        }
    }

    private func liveStatRow(icon: String, titleKey: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 48, height: 48)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(titleKey))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VendorLiveView(homeViewModel: VendorHomeViewModel(), onStop: {})
        .environment(\.locale, Locale(identifier: "en"))
}
