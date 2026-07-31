import MapKit
import SwiftUI
import UIKit

struct VendorHomeView: View {
    enum ActiveSheet: Identifiable {
        case preLive
        case workingMap
        case myDay
        case recorder
        case requests
        case hoursEditor
        case offerings

        var id: Int {
            switch self {
            case .preLive: return 0
            case .workingMap: return 1
            case .myDay: return 2
            case .recorder: return 3
            case .requests: return 4
            case .hoursEditor: return 5
            case .offerings: return 6
            }
        }
    }

    @ObservedObject var viewModel: VendorHomeViewModel
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    var onSelectTab: (VendorTab) -> Void = { _ in }

    @State private var activeSheet: ActiveSheet?
    @ObservedObject private var geo = VendorGeoContext.shared

    private let vendorID = VendorIdentityStore.vendorID

    private var isLiveSurface: Bool {
        liveSession.state == .live || liveSession.state == .preparing || liveSession.state == .stopping
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                brandedHeader

                if case .failed(let message) = liveSession.state {
                    errorBanner(message, tint: AppTheme.danger)
                } else if let error = liveSession.errorMessage {
                    errorBanner(error, tint: AppTheme.accent)
                }

                contextualLocationSection

                if isLiveSurface {
                    liveCompactDashboard
                } else {
                    preparationSection
                    goLiveAction
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
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
                    businessName: businessDisplayName,
                    onGoLive: {
                        activeSheet = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(200))
                            liveSession.prepareAndGoLive()
                        }
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
            case .requests:
                VendorRequestsInboxView(liveSession: liveSession)
            case .hoursEditor:
                VendorHoursEditorSheet(liveSession: liveSession) {
                    activeSheet = nil
                }
            case .offerings:
                NavigationStack {
                    VendorInventoryView(category: liveSession.vendorCategory) {
                        liveSession.markInventoryReady(true)
                        activeSheet = nil
                    }
                }
            }
        }
    }

    private var businessDisplayName: String {
        "\(viewModel.vendorName) \(liveSession.vendorCategory.englishTitle)"
    }

    private func refreshBusinessSummary() {
        let hours = liveSession.liveStartedAt.map { Date().timeIntervalSince($0) / 3600 } ?? 0
        viewModel.refreshSummary(vendorID: vendorID, liveHours: hours)
    }

    // MARK: - Branded header

    private var brandedHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image("BrandMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("RediWala")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Vendor")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 8)

                statusBadge
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.vendorName)
                    .font(.title.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 8) {
                    Label(liveSession.selectedOperatingArea.localizedName, systemImage: "mappin.and.ellipse")
                    Text("·")
                        .foregroundStyle(AppTheme.textSecondary)
                    Label(liveSession.vendorCategory.englishTitle, systemImage: liveSession.vendorCategory.systemImage)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)

                HStack(spacing: 8) {
                    Text(liveSession.serviceMode.title)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.background)
                        .clipShape(Capsule())

                    if isLiveSurface {
                        Text(liveSession.liveDurationText)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isLiveSurface ? AppTheme.primary : AppTheme.textSecondary.opacity(0.45))
                .frame(width: 8, height: 8)
            Text(isLiveSurface ? "Online" : "Offline")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(isLiveSurface ? AppTheme.primary : AppTheme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            (isLiveSurface ? AppTheme.primary : AppTheme.textSecondary).opacity(0.12)
        )
        .clipShape(Capsule())
        .accessibilityLabel(Text(isLiveSurface ? "Online" : "Offline"))
    }

    // MARK: - Contextual location (mode-driven)

    @ViewBuilder
    private var contextualLocationSection: some View {
        switch liveSession.serviceMode {
        case .mobile:
            mobileRouteMapHero
        case .stationary:
            stationaryLocationCard
        case .scheduled:
            scheduledTimelineCard
        }
    }

    private var mobileRouteMapHero: some View {
        Button {
            activeSheet = .workingMap
        } label: {
            ZStack(alignment: .bottomLeading) {
                Map(position: .constant(geo.cameraPosition)) {
                    let circuit = circuitCoordinates
                    if circuit.count >= 2 {
                        MapPolyline(coordinates: circuit)
                            .stroke(AppTheme.primary, lineWidth: 3)
                    }
                    ForEach(liveSession.routeStops.filter { !$0.isCompleted }.prefix(8)) { stop in
                        Annotation(stop.title, coordinate: stop.coordinate.mapCoordinate) {
                            Circle()
                                .fill(stop.isCurrent ? AppTheme.primary : AppTheme.info)
                                .frame(width: stop.isCurrent ? 12 : 8, height: stop.isCurrent ? 12 : 8)
                        }
                    }
                    if isLiveSurface {
                        ForEach(liveSession.demandClusters.prefix(4)) { cluster in
                            Annotation("\(cluster.customerCount)", coordinate: cluster.coordinate.mapCoordinate) {
                                Text("\(cluster.customerCount)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(5)
                                    .background(AppTheme.accent)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 2) {
                    if let current = liveSession.currentStop {
                        Text("Next · \(current.title)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        if let eta = etaLabel(for: current) {
                            Text(eta)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    } else {
                        Text("Route map")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    Text("Open map")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(12)
                .background(.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(12)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Route map"))
    }

    private var stationaryLocationCard: some View {
        Button {
            activeSheet = .workingMap
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current location")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(liveSession.selectedOperatingArea.localizedName)
                        .font(.headline.weight(.bold))
                    Text(liveSession.stationaryLandmark.isEmpty
                         ? liveSession.currentLocationText
                         : liveSession.stationaryLandmark)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(14)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var scheduledTimelineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Schedule")
                    .font(.headline.weight(.bold))
                Spacer()
                Button("Edit") { activeSheet = .myDay }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }

            let upcoming = liveSession.routeStops.filter { !$0.isCompleted }.prefix(4)
            if upcoming.isEmpty {
                Text("Add stops for today's rounds")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(Array(upcoming)) { stop in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(stop.isCurrent ? AppTheme.primary : AppTheme.info)
                                .frame(width: 10, height: 10)
                            if stop.id != upcoming.last?.id {
                                Rectangle()
                                    .fill(AppTheme.textSecondary.opacity(0.25))
                                    .frame(width: 2, height: 28)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.title)
                                .font(.subheadline.weight(.semibold))
                            Text(etaLabel(for: stop) ?? stop.landmark)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        if stop.isCurrent {
                            Text("Now")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var circuitCoordinates: [CLLocationCoordinate2D] {
        let active = liveSession.routeStops.filter { !$0.isCompleted }
        var coords = active.map(\.coordinate.mapCoordinate)
        if let first = coords.first, let last = coords.last,
           first.latitude != last.latitude || first.longitude != last.longitude {
            coords.append(first)
        }
        return coords
    }

    private func etaLabel(for stop: VendorRouteStopPlan) -> String? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "ETA \(formatter.string(from: stop.arrivalTime))"
    }

    // MARK: - Level 2 · Preparation

    private var preparationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedText.resolve("prep.title", fallback: "Preparation"))
                .font(.title3.weight(.bold))

            Text("Edit everything here. Confirmation happens once.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            prepRow(
                icon: liveSession.serviceMode.prepRouteIcon,
                done: liveSession.hasRouteOrLocationPrepared,
                title: liveSession.serviceMode.prepRouteTitle,
                subtitle: routeOrLocationSubtitle
            ) {
                if liveSession.serviceMode == .stationary {
                    activeSheet = .workingMap
                } else {
                    activeSheet = .myDay
                }
            }

            prepRow(
                icon: "basket.fill",
                done: liveSession.inventoryReady,
                title: LocalizedText.resolve("prep.offerings", fallback: "Today's Offerings"),
                subtitle: liveSession.inventoryReady ? "Ready for today" : "Mark what's available"
            ) {
                activeSheet = .offerings
            }

            prepRow(
                icon: "mic.fill",
                done: liveSession.hasAnnouncementPrepared,
                title: LocalizedText.resolve("prep.announcement", fallback: "Announcement"),
                subtitle: announcementSubtitle
            ) {
                activeSheet = .recorder
            }

            prepRow(
                icon: "clock.fill",
                done: liveSession.operatingHoursConfirmed,
                title: LocalizedText.resolve("prep.hours", fallback: "Operating Hours"),
                subtitle: hoursSubtitle
            ) {
                activeSheet = .hoursEditor
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var routeOrLocationSubtitle: String {
        switch liveSession.serviceMode {
        case .stationary:
            return liveSession.selectedOperatingArea.localizedName
        case .mobile, .scheduled:
            if liveSession.routeStops.isEmpty { return "Add stops" }
            let remaining = liveSession.routeStops.filter { !$0.isCompleted }.count
            if let current = liveSession.routeStops.first(where: \.isCurrent)?.title {
                return "Next: \(current) · \(remaining) left"
            }
            return "\(remaining) stops · \(liveSession.selectedOperatingArea.localizedName)"
        }
    }

    private var announcementSubtitle: String {
        guard let announcement = liveSession.announcement else {
            return "Optional · Record today's message"
        }
        let status: String
        switch liveSession.announcementSyncState {
        case .uploading:
            status = LocalizedText.resolve("announcement.sync.uploading", fallback: "Uploading…")
        case .waitingForConnection:
            status = LocalizedText.resolve("announcement.sync.queued", fallback: "Waiting for connection…")
        case .uploaded:
            status = LocalizedText.resolve("announcement.sync.uploaded", fallback: "Uploaded")
        case .idle:
            status = announcement.storagePath == nil
                ? LocalizedText.resolve("announcement.sync.queued", fallback: "Waiting for connection…")
                : LocalizedText.resolve("announcement.sync.uploaded", fallback: "Uploaded")
        }
        return "\(status) · \(announcement.durationSeconds)s"
    }

    private var hoursSubtitle: String {
        if liveSession.operatingHoursConfirmed {
            return liveSession.operatingHoursDisplayText
        }
        return "Set today's open window"
    }

    /// Consistent pattern: Icon · Title · State · Disclosure
    private func prepRow(
        icon: String,
        done: Bool,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : icon)
                    .foregroundStyle(done ? AppTheme.primary : AppTheme.textSecondary)
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Level 3 · Primary action

    private var goLiveAction: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !liveSession.isFirebaseReady {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Connecting…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            PrimaryButton(
                titleKey: "Go Live",
                systemImage: "antenna.radiowaves.left.and.right",
                isEnabled: liveSession.canStartLive,
                prominent: true
            ) {
                activeSheet = .preLive
            }

            Text(liveSession.isPreparationChecklistComplete
                 ? "One confirmation · then customers can find you."
                 : liveSession.preparationStatusSummary)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Live dashboard (mode-adaptive)

    private var liveCompactDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Live now")
                    .font(.title3.weight(.heavy))
                Spacer()
                Text("\(liveSession.waitingCustomersCount) waiting")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }

            switch liveSession.serviceMode {
            case .mobile:
                if let current = liveSession.currentStop {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Now")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(current.title)
                            .font(.title2.weight(.bold))
                        if let next = liveSession.nextStop {
                            Text("Next · \(next.title)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.info)
                        }
                    }
                }
            case .stationary:
                VStack(alignment: .leading, spacing: 4) {
                    Text("Serving from")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(liveSession.selectedOperatingArea.localizedName)
                        .font(.title2.weight(.bold))
                    Text(liveSession.stationaryLandmark.isEmpty
                         ? liveSession.currentLocationText
                         : liveSession.stationaryLandmark)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            case .scheduled:
                if let current = liveSession.currentStop {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current stop")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(current.title)
                            .font(.title2.weight(.bold))
                        if let eta = etaLabel(for: current) {
                            Text(eta)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.info)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                liveStat(title: "On air", value: liveSession.liveDurationText)
                liveStat(title: "Messages", value: "\(liveSession.openRequestCount)")
            }

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
                    }
                    .font(.caption.weight(.semibold))
                }
                .padding(12)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if liveSession.serviceMode != .stationary, let top = liveSession.demandClusters.first {
                Button {
                    activeSheet = .workingMap
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(top.customerCount) customers nearby")
                                .font(.subheadline.weight(.bold))
                            Text(top.productHints.prefix(2).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text("Detour")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                    .padding(14)
                    .background(AppTheme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text("Core actions")
                .font(.headline.weight(.bold))
                .padding(.top, 4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                liveActionTile(
                    title: liveSession.serviceMode == .scheduled ? "Schedule" : (liveSession.serviceMode == .stationary ? "Location" : "Map"),
                    subtitle: liveSession.serviceMode == .scheduled ? "Stops & arrivals" : "Neighborhood view",
                    systemImage: liveSession.serviceMode == .scheduled ? "calendar" : "map.fill",
                    tint: AppTheme.primary
                ) {
                    if liveSession.serviceMode == .scheduled {
                        activeSheet = .myDay
                    } else {
                        activeSheet = .workingMap
                    }
                }

                liveActionTile(
                    title: liveSession.serviceMode == .stationary ? "Area" : "Route",
                    subtitle: liveSession.serviceMode == .stationary ? "Where you stand" : "Edit today's path",
                    systemImage: liveSession.serviceMode == .stationary ? "mappin.circle.fill" : "point.topleft.down.to.point.bottomright.curvepath",
                    tint: AppTheme.info
                ) {
                    if liveSession.serviceMode == .stationary {
                        activeSheet = .workingMap
                    } else {
                        activeSheet = .myDay
                    }
                }

                liveActionTile(
                    title: "Messages",
                    subtitle: liveSession.openRequestCount > 0
                        ? "\(liveSession.openRequestCount) open"
                        : "Customer requests",
                    systemImage: "bubble.left.and.bubble.right.fill",
                    tint: AppTheme.accent
                ) {
                    onSelectTab(.messages)
                }

                liveActionTile(
                    title: "Business",
                    subtitle: "Sales & collect",
                    systemImage: "chart.bar.fill",
                    tint: AppTheme.primary
                ) {
                    onSelectTab(.earnings)
                }
            }

            PrimaryButton(
                titleKey: "Stop Live",
                systemImage: "stop.fill",
                style: .danger,
                isEnabled: liveSession.canStopLive,
                prominent: true
            ) {
                liveSession.stopLive()
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func liveActionTile(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .padding(14)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func liveStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

/// Inline hours — shows Open window, not just "Confirmed".
struct VendorHoursEditorSheet: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    var onDone: () -> Void
    @State private var openHour: Date
    @State private var closeHour: Date

    init(liveSession: VendorLiveSessionViewModel, onDone: @escaping () -> Void) {
        self.liveSession = liveSession
        self.onDone = onDone
        _openHour = State(initialValue: Self.date(fromMinutes: liveSession.todayOpenMinutes))
        _closeHour = State(initialValue: Self.date(fromMinutes: liveSession.todayCloseMinutes))
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Open", selection: $openHour, displayedComponents: .hourAndMinute)
                DatePicker("Close", selection: $closeHour, displayedComponents: .hourAndMinute)
                Text(previewLabel)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }
            .navigationTitle("Operating Hours")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        liveSession.setOperatingHours(
                            openMinutes: Self.minutes(from: openHour),
                            closeMinutes: Self.minutes(from: closeHour)
                        )
                        onDone()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var previewLabel: String {
        let open = Self.fmt.string(from: openHour)
        let close = Self.fmt.string(from: closeHour)
        return "Open \(open) – \(close)"
    }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private static func date(fromMinutes minutes: Int) -> Date {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func minutes(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}

#Preview {
    VendorHomeView(viewModel: VendorHomeViewModel(), liveSession: VendorLiveSessionViewModel(vendorId: "vendor_001"))
}
