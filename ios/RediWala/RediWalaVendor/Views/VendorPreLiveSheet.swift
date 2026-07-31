import SwiftUI

/// Lightweight confirmation only — preparation already happened on Home.
struct VendorPreLiveSheet: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    let businessName: String
    let onGoLive: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                header
                identityCard
                preparationStatus
                workingModeSection
                Spacer(minLength: 8)
                actionSection
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel", role: .cancel, action: onCancel)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(liveSession.state == .preparing)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Start Your Day")
                .font(.largeTitle.weight(.heavy))
            Text("Confirm once — then go live.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            identityRow(title: "Business", value: businessName)
            identityRow(title: "Neighborhood", value: liveSession.selectedOperatingArea.localizedName)
            identityRow(title: "Business Type", value: liveSession.vendorCategory.englishTitle)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func identityRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    private var preparationStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: liveSession.isPreparationChecklistComplete
                  ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundStyle(liveSession.isPreparationChecklistComplete ? AppTheme.primary : AppTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Preparation")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(liveSession.preparationStatusSummary)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var workingModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Working Mode")
                .font(.headline.weight(.bold))
            HStack(spacing: 8) {
                ForEach(VendorServiceMode.allCases) { mode in
                    Button {
                        liveSession.selectServiceMode(mode)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.body.weight(.semibold))
                            Text(mode.title)
                                .font(.caption2.weight(.bold))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(liveSession.serviceMode == mode ? Color.white : AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(liveSession.serviceMode == mode ? AppTheme.primary : AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(liveSession.state == .preparing)
                }
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            if liveSession.state == .preparing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Going live…")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }

            PrimaryButton(
                titleKey: "Go Live",
                systemImage: "antenna.radiowaves.left.and.right",
                isEnabled: liveSession.canStartLive,
                prominent: true
            ) {
                onGoLive()
            }

            Text(liveSession.canStartLive
                 ? "Customers nearby will see you as ONLINE."
                 : "Finish preparation on Home, then return here.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
