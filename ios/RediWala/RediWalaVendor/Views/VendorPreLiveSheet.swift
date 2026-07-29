import SwiftUI

/// Pre-live checklist. One clear path: Go Live. Recording is optional before that.
struct VendorPreLiveSheet: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    /// Primary action — go live now (with existing message if any).
    let onGoLive: () -> Void
    /// Optional: record a new message first, then go live.
    let onRecordThenGoLive: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    modeSection
                    messageStatus
                    actionSection
                }
                .padding(20)
            }
            .scrollIndicators(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel", role: .cancel, action: onCancel)
                }
            }
        }
        .interactiveDismissDisabled(liveSession.state == .preparing)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ready to Go Live?")
                .font(.largeTitle.weight(.heavy))
            Text("நேரலையில் செல்ல தயாரா?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(String(localized: String.LocalizationValue(liveSession.selectedOperatingArea.labelKey)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you working today?")
                .font(.headline.weight(.bold))
            ForEach(VendorServiceMode.allCases) { mode in
                Button {
                    liveSession.serviceMode = mode
                } label: {
                    HStack {
                        Image(systemName: mode.icon)
                            .foregroundStyle(AppTheme.primary)
                        VStack(alignment: .leading) {
                            Text(mode.title).font(.body.weight(.semibold))
                            Text(mode.tamilTitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        if liveSession.serviceMode == mode {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.primary)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(liveSession.state == .preparing)
            }
        }
    }

    private var messageStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: liveSession.announcement == nil ? "mic.slash" : "mic.fill")
                .font(.title3)
                .foregroundStyle(liveSession.announcement == nil ? AppTheme.textSecondary : AppTheme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(liveSession.announcement == nil ? "No message yet" : "Message ready")
                    .font(.subheadline.weight(.bold))
                Text(
                    liveSession.announcement == nil
                        ? "You can go live without one, or record first."
                        : "Will use your saved message when you go live."
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            if liveSession.state == .preparing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Going live…")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // One primary button — always goes live.
            PrimaryButton(
                titleKey: liveSession.announcement == nil ? "Go Live Now" : "Go Live with Message",
                systemImage: "antenna.radiowaves.left.and.right",
                isEnabled: liveSession.canStartLive,
                prominent: true
            ) {
                onGoLive()
            }

            // Optional: record first, then go live automatically after save.
            PrimaryButton(
                titleKey: liveSession.announcement == nil ? "Record Message, Then Go Live" : "Record New Message, Then Go Live",
                systemImage: "mic.fill",
                style: .accent,
                isEnabled: liveSession.canStartLive
            ) {
                onRecordThenGoLive()
            }

            Text("Customers nearby will see you as LIVE.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
