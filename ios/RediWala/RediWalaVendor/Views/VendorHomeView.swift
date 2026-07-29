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
        case todaySales

        var id: Int {
            switch self {
            case .preLive: return 0
            case .workingMap: return 1
            case .myDay: return 2
            case .recorder: return 3
            case .billCustomer: return 4
            case .requests: return 5
            case .todaySales: return 6
            }
        }
    }

    @ObservedObject var viewModel: VendorHomeViewModel
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    var onSelectTab: (VendorTab) -> Void = { _ in }

    @State private var greetingVisible = false
    @State private var statusVisible = false
    @State private var activeSheet: ActiveSheet?
    @State private var mapFocusCluster: DemandCluster?

    private let vendorID = VendorIdentityStore.vendorID

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

                StatusCard(titleKey: liveSession.state == .live ? "status.live" : "status.offline", isLive: liveSession.state == .live)
                    .opacity(statusVisible ? 1 : 0)
                    .offset(y: statusVisible ? 0 : 10)

                if case .failed(let message) = liveSession.state {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.danger)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.danger.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else if let error = liveSession.errorMessage {
                    Text(error)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if liveSession.state == .live || liveSession.state == .preparing || liveSession.state == .stopping {
                    liveDashboardSection
                } else {
                    goLiveCard
                }

                todaysRouteSection
                opportunitiesSection

                if liveSession.state == .live {
                    billCustomerCard
                }

                announcementSection
                summarySection
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.visible)
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
            refreshBusinessSummary()
        }
        .onChange(of: liveSession.liveElapsedSeconds) { _, _ in
            refreshBusinessSummary()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .preLive:
                VendorPreLiveSheet(
                    liveSession: liveSession,
                    onGoLive: {
                        // Dismiss first, then go live so sheet animation doesn't block UI.
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
                    // Cancelled without save — do not auto go live.
                    if liveSession.state != .live, liveSession.state != .preparing {
                        liveSession.clearGoLiveAfterRecording()
                    }
                }
            case .billCustomer:
                VendorCollectMoneyView(
                    vendorID: vendorID,
                    vendorName: viewModel.vendorName,
                    businessName: "\(viewModel.vendorName) Vegetables"
                ) { _ in
                    refreshBusinessSummary()
                }
            case .requests:
                VendorRequestsInboxView(liveSession: liveSession)
            case .todaySales:
                VendorTodaySalesView(vendorID: vendorID)
            }
        }
    }

    private func refreshBusinessSummary() {
        let hours = liveSession.liveStartedAt.map { Date().timeIntervalSince($0) / 3600 } ?? 0
        viewModel.refreshSummary(vendorID: vendorID, liveHours: hours)
    }

    private var todaysRouteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "route.today.title")
            if liveSession.routeStops.isEmpty {
                Text("route.today.empty")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(liveSession.routeStops.prefix(3)) { stop in
                    HStack {
                        Image(systemName: stop.isCurrent ? "mappin.circle.fill" : "mappin.circle")
                            .foregroundStyle(stop.isCurrent ? AppTheme.primary : AppTheme.textSecondary)
                        VStack(alignment: .leading) {
                            Text(stop.title).font(.subheadline.weight(.semibold))
                            Text(Self.timeFormatter.string(from: stop.arrivalTime))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            Button("route.today.manage") {
                activeSheet = .myDay
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var opportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "demand.waiting.title")

            if liveSession.demandClusters.isEmpty {
                Text("demand.waiting.empty")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(liveSession.demandClusters.prefix(3)) { cluster in
                    Button {
                        mapFocusCluster = cluster
                        activeSheet = .workingMap
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cluster.peopleWaitingText)
                                    .font(.subheadline.weight(.bold))
                                Text(cluster.neighborhoodName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("demand.requests.title") {
                activeSheet = .requests
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var billCustomerCard: some View {
        PrimaryButton(
            titleKey: "money.collect.title",
            systemImage: "indianrupeesign.circle.fill",
            isEnabled: true,
            prominent: true
        ) {
            activeSheet = .billCustomer
        }
    }

    private var announcementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(titleKey: "business.announcement.title")
            if let announcement = liveSession.announcement {
                Text("Recorded · \(announcement.durationSeconds)s")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                Text("business.announcement.empty")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Button("business.announcement.record") {
                activeSheet = .recorder
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var goLiveCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !liveSession.isFirebaseReady {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Connecting to Firebase…")
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
            Text("Pick how you work, then go live. Message is optional.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var greetingSection: some View {
        HStack(alignment: .center, spacing: 12) {
            vendorPhoto
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

                Text("tab.my_business")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var vendorPhoto: some View {
        if let path = liveSession.profilePhotoLocalPath,
           let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(AppTheme.primary.opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay {
                    Text(viewModel.vendorName.prefix(2).uppercased())
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                }
        }
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

            Button("money.today.title") {
                activeSheet = .todaySales
            }
            .buttonStyle(.bordered)
            .font(.subheadline.weight(.semibold))
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(titleKey: "home.quick_actions")

            VStack(spacing: 12) {
                LargeActionButton(
                    titleKey: "map.area.title",
                    subtitleKey: "map.area.subtitle",
                    systemImage: "map.fill",
                    tint: AppTheme.primary
                ) {
                    activeSheet = .workingMap
                }

                LargeActionButton(
                    titleKey: "route.today.title",
                    subtitleKey: "route.today.subtitle",
                    systemImage: "calendar.badge.clock",
                    tint: AppTheme.info
                ) {
                    activeSheet = .myDay
                }

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

    private var liveDashboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIVE Dashboard")
                .font(.title3.weight(.heavy))
            row("Mode", value: liveSession.serviceMode.title)
            row("Location", value: liveSession.currentLocationText)
            row("Live for", value: liveSession.liveDurationText)
            row("Live until", value: liveSession.presenceExpiresText)
            row("Next confirmation", value: liveSession.nextPresenceCheckText)
            row("Next broadcast", value: liveSession.nextBroadcastAt.map { Self.timeFormatter.string(from: $0) } ?? "Off")

            if liveSession.showPresencePrompt {
                VStack(alignment: .leading, spacing: 10) {
                    Text("presence.still_here")
                        .font(.headline.weight(.bold))
                    Text("presence.warning")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 8) {
                        Button("presence.yes") { liveSession.confirmStillHere() }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.primary)
                        Button("presence.extend") { liveSession.extendPresence(byMinutes: 60) }
                            .buttonStyle(.bordered)
                        Button("presence.go_offline", role: .destructive) { liveSession.stopLive() }
                            .buttonStyle(.bordered)
                    }
                    .font(.caption.weight(.semibold))
                }
                .padding(12)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 8) {
                Button("View Map") { activeSheet = .workingMap }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                Button("Play Now") { liveSession.playNow() }
                    .buttonStyle(.bordered)
                Button(liveSession.isBroadcastPaused ? "Resume Broadcast" : "Pause Broadcast") {
                    liveSession.isBroadcastPaused ? liveSession.resumeBroadcast() : liveSession.pauseBroadcast()
                }
                .buttonStyle(.bordered)
            }

            if liveSession.state == .preparing {
                ProgressView("Going live…")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if liveSession.state == .stopping {
                ProgressView("Stopping…")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(role: .destructive) {
                liveSession.stopLive()
            } label: {
                Text("Stop Live")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.danger)
            .disabled(!liveSession.canStopLive)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(_ key: String, value: String) -> some View {
        HStack {
            Text(key).font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

#Preview("Offline") {
    VendorHomeView(viewModel: VendorHomeViewModel(), liveSession: VendorLiveSessionViewModel(vendorId: "vendor_001"))
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Live") {
    VendorHomeView(
        viewModel: VendorHomeViewModel(),
        liveSession: {
            let vm = VendorLiveSessionViewModel(vendorId: "vendor_001")
            vm.prepareAndGoLive()
            return vm
        }()
    )
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Dark") {
    VendorHomeView(viewModel: VendorHomeViewModel(), liveSession: VendorLiveSessionViewModel(vendorId: "vendor_001"))
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
