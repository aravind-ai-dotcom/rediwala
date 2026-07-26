import SwiftUI

struct VendorLiveView: View {
    @ObservedObject var homeViewModel: VendorHomeViewModel
    @StateObject private var liveViewModel = VendorLiveViewModel()
    var onStop: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            StatusCard(title: "LIVE", isLive: true)

            VStack(spacing: 12) {
                liveStatRow(icon: "location.fill", title: "Location", value: liveViewModel.locationLabel)
                liveStatRow(icon: "clock.fill", title: "Start Time", value: liveViewModel.startTimeLabel)
                liveStatRow(
                    icon: "person.2.fill",
                    title: "Customers Today",
                    value: "\(liveViewModel.customersToday)"
                )
            }

            Spacer(minLength: 0)

            PrimaryButton(
                title: "STOP",
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

    private func liveStatRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 48, height: 48)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
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
}
