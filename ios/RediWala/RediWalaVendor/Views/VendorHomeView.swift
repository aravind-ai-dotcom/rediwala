import MapKit
import SwiftUI
import UIKit

struct VendorHomeView: View {
    enum ActiveSheet: Identifiable {
        case preLive
        case workingMap
        case myDay
        case recorder
        case billCustomer
        case requests
        case hoursEditor

        var id: Int {
            switch self {
            case .preLive: return 0
            case .workingMap: return 1
            case .myDay: return 2
            case .recorder: return 3
            case .billCustomer: return 4
            case .requests: return 5
            case .hoursEditor: return 6
            }
        }
    }

    @ObservedObject var viewModel: VendorHomeViewModel
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    var onSelectTab: (VendorTab) -> Void = { _ in }

    @State private var activeSheet: ActiveSheet?
    @ObservedObject private var geo = VendorGeoContext.shared

    private let vendorID = VendorIdentityStore.vendorID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                mapHero
                statusStrip
                if case .failed(let message) = liveSession.state {
                    errorBanner(message, tint: AppTheme.danger)
                } else if let error = liveSession.errorMessage {
                    errorBanner(error, tint: AppTheme.accent)
                }

                if liveSession.state == .live || liveSession.state == .preparing || liveSession.state == .stopping {
                    liveCompactDashboard
                } else {
                    preparationSection
                    nextActionCard
                }

                if liveSession.state == .live {
                    PrimaryButton(
                        titleKey: "money.collect.title",
                        systemImage: "indianrupeesign.circle.fill",
                        isEnabled: true,
                        prominent: true
                    ) {
                        activeSheet = .billCustomer
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear { refreshBusinessSummary() }
        .onChange(of: liveSession.liveElapsedSeconds) { _, _ in refreshBusinessSummary() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .preLive:
                VendorPreLiveSheet(
                    liveSession: liveSession,
                    onGoLive: {
                        activeSheet = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(200))
                            liveSession.prepareAndGoLive()
                        }
                    },
                    onRecordThenGoLive: {
                        liveSession.markGoLiveAfterRecording()
                        activeSheet = .recorder
                    },
                    onCancel: {
                        liveSession.clearGoLiveAfterRecording()
                        activeSheet = nil
                    }
                )
            case .workingMap:
                VendorWorkingMapView(liveSession: liveSession)
            case .myDay:
                VendorMyDayView(liveSession: liveSession)
            case .recorder:
                VendorAnnouncementRecorderView(
                    vendorID: VendorIdentityStore.vendorID,
                    liveSessionID: nil,
                    proceedsToGoLive: liveSession.goLiveAfterRecording
                ) { draft in
                    let shouldGoLive = liveSession.goLiveAfterRecording
                    liveSession.updateAnnouncement(draft)
                    liveSession.clearGoLiveAfterRecording()
                    activeSheet = nil
                    if shouldGoLive {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(250))
                            liveSession.prepareAndGoLive()
                        }
                    }
                }
                .onDisappear {
                    if liveSession.state != .live, liveSession.state != .preparing {
                        liveSession.clearGoLiveAfterRecording()
                    }
                }
            case .billCustomer:
                VendorCollectMoneyView(
                    vendorID: vendorID,
                    vendorName: viewModel.vendorName,
                    businessName: "\(viewModel.vendorName) Vegetables"
                ) { _ in refreshBusinessSummary() }
            case .requests:
                VendorRequestsInboxView(liveSession: liveSession)
            case .hoursEditor:
                VendorHoursEditorSheet(liveSession: liveSession) {
                    liveSession.markOperatingHoursConfirmed(true)
                    activeSheet = nil
                }
            }
        }
    }

    private func refreshBusinessSummary() {
        let hours = liveSession.liveStartedAt.map { Date().timeIntervalSince($0) / 3600 } ?? 0
        viewModel.refreshSummary(vendorID: vendorID, liveHours: hours)
    }

    // MARK: - Map as persistent anchor

    private var mapHero: some View {
        Button {
            activeSheet = .workingMap
        } label: {
            ZStack(alignment: .bottomLeading) {
                Map(position: .constant(geo.cameraPosition)) {
                    Annotation(viewModel.vendorName, coordinate: geo.coordinate) {
                        Circle()
                            .fill(liveSession.state == .live ? AppTheme.primary : AppTheme.info)
                            .frame(width: 14, height: 14)
                    }
                }
                .mapStyle(.standard)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.vendorName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(liveSession.selectedOperatingArea.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(12)
                .background(.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(12)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("map.area.title"))
    }

    private var statusStrip: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(liveSession.state == .live ? AppTheme.primary : AppTheme.textSecondary.opacity(0.4))
                .frame(width: 10, height: 10)
            Text(liveSession.state == .live ? "Live" : "Offline")
                .font(.subheadline.weight(.bold))
            Spacer()
            Text(liveSession.selectedOperatingArea.localizedName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            if liveSession.state == .live {
                Text(liveSession.liveDurationText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var preparationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedText.resolve("prep.title", fallback: "Today's Prep"))
                .font(.title3.weight(.bold))

            prepRow(
                done: liveSession.hasRoutePrepared,
                title: LocalizedText.resolve("prep.route", fallback: "Today's Route"),
                subtitle: routeSubtitle
            ) { activeSheet = .myDay }

            prepRow(
                done: liveSession.inventoryReady,
                title: LocalizedText.resolve("prep.offerings", fallback: "Today's Offerings"),
                subtitle: liveSession.inventoryReady ? "Ready for today" : "Mark what's available"
            ) {
                liveSession.markInventoryReady(true)
                onSelectTab(.inventory)
            }

            prepRow(
                done: liveSession.hasAnnouncementPrepared,
                title: LocalizedText.resolve("prep.announcement", fallback: "Announcement"),
                subtitle: announcementSubtitle
            ) { activeSheet = .recorder }

            prepRow(
                done: liveSession.operatingHoursConfirmed,
                title: LocalizedText.resolve("prep.hours", fallback: "Operating Hours"),
                subtitle: hoursSubtitle
            ) { activeSheet = .hoursEditor }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var routeSubtitle: String {
        if liveSession.routeStops.isEmpty { return "Add stops" }
        let remaining = liveSession.routeStops.filter { !$0.isCompleted }.count
        return "\(remaining) stops · \(liveSession.selectedOperatingArea.localizedName)"
    }

    private var announcementSubtitle: String {
        if let announcement = liveSession.announcement {
            return LocalizedText.resolve("announcement.sync.uploaded", fallback: "Uploaded")
                + " · \(announcement.durationSeconds)s"
        }
        return "Record today's message"
    }

    private var hoursSubtitle: String {
        liveSession.operatingHoursConfirmed ? "Confirmed for today" : "Set today's window"
    }

    private func prepRow(done: Bool, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? AppTheme.primary : AppTheme.textSecondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var nextActionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedText.resolve("home.next_action", fallback: "Next Action"))
                .font(.headline.weight(.bold))

            if !liveSession.isFirebaseReady {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Connecting…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            PrimaryButton(
                titleKey: "home.go_live",
                systemImage: "antenna.radiowaves.left.and.right",
                isEnabled: liveSession.canStartLive,
                prominent: true
            ) {
                activeSheet = .preLive
            }

            Text(liveSession.isPreparationChecklistComplete
                 ? "Ready — customers nearby will see you."
                 : "Finish Today's Prep to go live.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var liveCompactDashboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Live")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                Text(liveSession.serviceMode.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(liveSession.currentLocationText)
                .font(.subheadline.weight(.semibold))
            HStack {
                Label(liveSession.liveDurationText, systemImage: "clock")
                Spacer()
                Label(liveSession.presenceExpiresText, systemImage: "hourglass")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)

            if liveSession.showPresencePrompt {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Still here?")
                        .font(.subheadline.weight(.bold))
                    HStack {
                        Button("Yes") { liveSession.confirmStillHere() }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.primary)
                        Button("Extend") { liveSession.extendPresence(byMinutes: 60) }
                            .buttonStyle(.bordered)
                        Button("Go Offline", role: .destructive) { liveSession.stopLive() }
                            .buttonStyle(.bordered)
                    }
                    .font(.caption.weight(.semibold))
                }
                .padding(10)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 8) {
                Button("Map") { activeSheet = .workingMap }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                Button("Route") { activeSheet = .myDay }
                    .buttonStyle(.bordered)
                Button("Stop", role: .destructive) { liveSession.stopLive() }
                    .buttonStyle(.bordered)
                    .disabled(!liveSession.canStopLive)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func errorBanner(_ message: String, tint: Color) -> some View {
        Text(message)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Inline hours confirmation — no separate deep screen.
struct VendorHoursEditorSheet: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    var onDone: () -> Void
    @State private var openHour = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var closeHour = Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Open", selection: $openHour, displayedComponents: .hourAndMinute)
                DatePicker("Close", selection: $closeHour, displayedComponents: .hourAndMinute)
                Text("\(Self.fmt.string(from: openHour)) – \(Self.fmt.string(from: closeHour))")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }
            .navigationTitle("Operating Hours")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        liveSession.markOperatingHoursConfirmed(true)
                        onDone()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

#Preview {
    VendorHomeView(viewModel: VendorHomeViewModel(), liveSession: VendorLiveSessionViewModel(vendorId: "vendor_001"))
}
