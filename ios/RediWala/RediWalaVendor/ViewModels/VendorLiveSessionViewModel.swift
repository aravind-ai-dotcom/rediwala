import AVFoundation
import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class VendorLiveSessionViewModel: ObservableObject {
    @Published private(set) var state: VendorLiveSessionState = .offline
    @Published var serviceMode: VendorServiceMode = .mobile
    @Published var selectedOperatingArea: ChennaiArea = .tNagar
    @Published var stationaryLandmark: String = "Pondy Bazaar"
    @Published var demandSignals: [VendorDemandSignal] = []
    @Published var demandClusters: [DemandCluster] = []
    @Published var routeRecommendations: [RouteRecommendation] = []
    @Published var customerRequests: [CustomerInterestRequest] = []
    @Published private(set) var geocodedAreaCoordinate: CodableCoordinate?
    @Published var routeStops: [VendorRouteStopPlan] = VendorServiceModeDemoData.defaultStops(for: .tNagar)
    @Published private(set) var liveStartedAt: Date?
    @Published private(set) var liveElapsedSeconds: Int = 0
    @Published private(set) var presenceExpiresAt: Date?
    @Published private(set) var presenceConfirmedAt: Date?
    @Published var showPresencePrompt = false
    @Published var currentLocationText: String = "—"
    @Published var errorMessage: String?
    @Published var isBroadcastPaused = false
    @Published var broadcastIntervalMinutes: Int? = nil
    @Published var nextBroadcastAt: Date?
    @Published var announcement: VendorAnnouncementDraft?
    @Published var selectedAudioOutputName: String = "Device Speaker"
    @Published var profilePhotoLocalPath: String?
    @Published var inventoryReady = false
    @Published var operatingHoursConfirmed = false
    @Published var todayOpenMinutes: Int = 8 * 60
    @Published var todayCloseMinutes: Int = 13 * 60
    @Published private(set) var announcementSyncState: AnnouncementSyncState = .idle
    @Published private(set) var vendorCategory: VendorCategory = .vegetables

    enum AnnouncementSyncState: Equatable {
        case idle
        case uploading
        case uploaded
        case waitingForConnection
    }

    private var livePrepareTask: Task<Void, Never>?
    private var stopTask: Task<Void, Never>?
    private var broadcastTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var presenceTask: Task<Void, Never>?
    private var announcementUploadTask: Task<Void, Never>?
    private var routeSyncTask: Task<Void, Never>?
    private var geocodeTask: Task<Void, Never>?
    private let demandRepository = VendorDemandRepository()
    private let vendorId: String
    private let firebase = VendorFirebaseService.shared
    private let firebaseSession = VendorFirebaseSession.shared
    private var cancellables = Set<AnyCancellable>()

    init(vendorId: String, category: VendorCategory = .vegetables) {
        self.vendorId = vendorId
        self.vendorCategory = category
        self.serviceMode = Self.loadPreferredMode(for: vendorId) ?? category.defaultServiceMode
        self.announcement = VendorAnnouncementStore.load(for: vendorId)
        if let loaded = self.announcement {
            announcementSyncState = loaded.storagePath == nil ? .waitingForConnection : .uploaded
        }
        self.profilePhotoLocalPath = VendorProfilePhotoStore.loadPath(for: vendorId)
        if let interval = announcement?.playbackIntervalMinutes {
            broadcastIntervalMinutes = interval
        }
        self.demandClusters = Self.demoClusters(for: selectedOperatingArea, category: category)
        restorePrepFlagsIfNeeded()
        restorePersistedSessionIfNeeded()
        updateLocationText()
        geocodeOperatingArea()
        geocodeRouteStops()
        bindDemandRepository()
        Task { await retryPendingAnnouncementUploadIfNeeded() }

        firebaseSession.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    deinit {
        livePrepareTask?.cancel()
        stopTask?.cancel()
        broadcastTask?.cancel()
        timerTask?.cancel()
        presenceTask?.cancel()
        announcementUploadTask?.cancel()
        routeSyncTask?.cancel()
        geocodeTask?.cancel()
    }

    var isFirebaseReady: Bool {
        firebaseSession.isReady
    }

    var canStartLive: Bool {
        guard firebaseSession.isReady else { return false }
        guard isPreparationChecklistComplete else { return false }
        switch state {
        case .offline, .failed:
            return true
        case .preparing, .live, .stopping:
            return false
        }
    }

    var canStopLive: Bool {
        switch state {
        case .live, .preparing:
            return true
        case .offline, .stopping, .failed:
            return false
        }
    }

    var liveDurationText: String {
        guard liveStartedAt != nil else { return "0 min" }
        let elapsed = liveElapsedSeconds
        let hours = elapsed / 3600
        let mins = (elapsed % 3600) / 60
        if hours > 0 { return "\(hours) hr \(mins) min" }
        return "\(mins) min"
    }

    var presenceExpiresText: String {
        guard let presenceExpiresAt else { return "—" }
        return Self.shortTime.string(from: presenceExpiresAt)
    }

    var nextPresenceCheckText: String {
        guard let presenceExpiresAt else { return "—" }
        let warning = presenceExpiresAt.addingTimeInterval(-10 * 60)
        return Self.shortTime.string(from: max(warning, Date()))
    }

    var minutesUntilPresenceExpiry: Int? {
        guard let presenceExpiresAt else { return nil }
        return max(0, Int(presenceExpiresAt.timeIntervalSinceNow / 60))
    }

    var hasRoutePrepared: Bool {
        routeStops.contains { !$0.isCompleted }
    }

    /// Stationary vendors need a place, not a multi-stop circuit.
    var hasLocationPrepared: Bool {
        !selectedOperatingArea.englishName.isEmpty
    }

    var hasRouteOrLocationPrepared: Bool {
        serviceMode.requiresRoute ? hasRoutePrepared : hasLocationPrepared
    }

    var hasAnnouncementPrepared: Bool {
        announcement != nil
    }

    /// Preparation happens on Home. Announcement is optional — never block Go Live.
    var isPreparationChecklistComplete: Bool {
        hasRouteOrLocationPrepared && inventoryReady && operatingHoursConfirmed
    }

    var preparationStatusSummary: String {
        if isPreparationChecklistComplete {
            let extras = hasAnnouncementPrepared ? " · Announcement ready" : ""
            return "Prep complete\(extras)"
        }
        var missing: [String] = []
        if !hasRouteOrLocationPrepared {
            missing.append(serviceMode.prepRouteTitle)
        }
        if !inventoryReady { missing.append("Offerings") }
        if !operatingHoursConfirmed { missing.append("Hours") }
        return "Still need: \(missing.joined(separator: ", "))"
    }

    var currentStop: VendorRouteStopPlan? {
        routeStops.first(where: { $0.isCurrent && !$0.isCompleted })
            ?? routeStops.first(where: { !$0.isCompleted })
    }

    var nextStop: VendorRouteStopPlan? {
        guard let current = currentStop,
              let idx = routeStops.firstIndex(where: { $0.id == current.id }) else {
            return routeStops.first(where: { !$0.isCompleted })
        }
        return routeStops.dropFirst(idx + 1).first(where: { !$0.isCompleted })
    }

    var waitingCustomersCount: Int {
        demandClusters.reduce(0) { $0 + $1.customerCount }
    }

    var openRequestCount: Int {
        customerRequests.filter { $0.status == .open }.count
    }

    private static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    /// True when the next recorder save should immediately go live.
    private(set) var goLiveAfterRecording = false

    func confirmStillHere() {
        extendPresence(byMinutes: serviceMode.presenceCheckIntervalMinutes)
    }

    func extendPresence(byMinutes minutes: Int) {
        guard state == .live else { return }
        let confirmed = Date()
        let expires = confirmed.addingTimeInterval(Double(minutes) * 60)
        presenceConfirmedAt = confirmed
        presenceExpiresAt = expires
        showPresencePrompt = false
        persistLiveSession(isLive: true)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.firebase.confirmPresence(
                    vendorID: self.vendorId,
                    serviceMode: self.serviceMode,
                    operatingArea: self.selectedOperatingArea,
                    landmark: self.currentLandmark(),
                    coordinate: self.currentCoordinate(),
                    extendByMinutes: minutes
                )
            } catch {
                self.errorMessage = "Presence updated on device. Cloud sync may be delayed."
            }
        }
    }

    func prepareAndGoLive() {
        guard canStartLive else {
            if !firebaseSession.isReady {
                errorMessage = "Connecting… wait a moment, then try Go Live again."
            }
            return
        }
        goLiveAfterRecording = false
        state = .preparing
        errorMessage = nil
        livePrepareTask?.cancel()
        livePrepareTask = Task { [weak self] in
            await self?.performPrepareSequence()
        }
    }

    /// Opens the record path that will call `prepareAndGoLive` after a successful save.
    func markGoLiveAfterRecording() {
        goLiveAfterRecording = true
    }

    func clearGoLiveAfterRecording() {
        goLiveAfterRecording = false
    }

    func stopLive() {
        guard canStopLive else { return }
        state = .stopping
        livePrepareTask?.cancel()
        stopTask?.cancel()
        stopTask = Task { [weak self] in
            await self?.performStopSequence()
        }
    }

    func pauseBroadcast() {
        isBroadcastPaused = true
        broadcastTask?.cancel()
        nextBroadcastAt = nil
    }

    func resumeBroadcast() {
        guard state == .live else { return }
        isBroadcastPaused = false
        scheduleBroadcastIfNeeded()
    }

    func setBroadcastInterval(_ minutes: Int?) {
        broadcastIntervalMinutes = minutes
        announcement?.playbackIntervalMinutes = minutes
        persistAnnouncement()
        scheduleBroadcastIfNeeded()
    }

    func playNow() {
        NotificationCenter.default.post(name: .vendorPlayAnnouncementNow, object: nil)
    }

    func updateAnnouncement(_ draft: VendorAnnouncementDraft?) {
        announcement = draft
        if draft != nil {
            announcementSyncState = .uploading
            objectWillChange.send()
        } else {
            announcementSyncState = .idle
        }
        persistAnnouncement()
        scheduleBroadcastIfNeeded()
        guard let draft else { return }
        announcementUploadTask?.cancel()
        announcementUploadTask = Task { [weak self] in
            await self?.uploadAnnouncement(draft)
        }
    }

    func retryPendingAnnouncementUploadIfNeeded() async {
        guard let draft = announcement, draft.storagePath == nil else {
            if announcement?.storagePath != nil {
                announcementSyncState = .uploaded
            }
            return
        }
        announcementSyncState = .uploading
        await uploadAnnouncement(draft)
    }

    private func uploadAnnouncement(_ draft: VendorAnnouncementDraft) async {
        do {
            let synced = try await firebase.saveAnnouncement(draft, vendorID: vendorId)
            guard !Task.isCancelled else { return }
            announcement = synced
            announcementSyncState = synced.storagePath == nil ? .waitingForConnection : .uploaded
            persistAnnouncement()
        } catch {
            guard !Task.isCancelled else { return }
            announcementSyncState = .waitingForConnection
            errorMessage = LocalizedText.resolve(
                "announcement.sync.queued",
                fallback: "Waiting for connection…"
            )
        }
    }

    func setProfilePhotoPath(_ path: String?) {
        profilePhotoLocalPath = path
    }

    func markInventoryReady(_ value: Bool) {
        inventoryReady = value
        persistPrepFlags()
    }

    func markOperatingHoursConfirmed(_ value: Bool) {
        operatingHoursConfirmed = value
        persistPrepFlags()
    }

    func setOperatingHours(openMinutes: Int, closeMinutes: Int) {
        todayOpenMinutes = openMinutes
        todayCloseMinutes = max(closeMinutes, openMinutes + 30)
        operatingHoursConfirmed = true
        persistPrepFlags()
    }

    func seedOperatingHours(openMinutes: Int, closeMinutes: Int) {
        todayOpenMinutes = openMinutes
        todayCloseMinutes = max(closeMinutes, openMinutes + 30)
    }

    private func persistPrepFlags() {
        VendorBusinessDayStore.savePrep(
            inventoryReady: inventoryReady,
            hoursConfirmed: operatingHoursConfirmed,
            openMinutes: todayOpenMinutes,
            closeMinutes: todayCloseMinutes,
            vendorID: vendorId
        )
    }

    private func restorePrepFlagsIfNeeded() {
        guard let prep = VendorBusinessDayStore.loadPrep(vendorID: vendorId) else { return }
        inventoryReady = prep.inventoryReady
        operatingHoursConfirmed = prep.hoursConfirmed
        todayOpenMinutes = prep.open
        todayCloseMinutes = prep.close
    }

    var operatingHoursDisplayText: String {
        let open = Self.shortTime.string(from: Self.date(fromMinutes: todayOpenMinutes))
        let close = Self.shortTime.string(from: Self.date(fromMinutes: todayCloseMinutes))
        return "Open \(open) – \(close)"
    }

    private static func date(fromMinutes minutes: Int) -> Date {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    func planMyRoute() {
        let origin = routeStops.first?.coordinate.mapCoordinate ?? resolvedAreaCoordinate().mapCoordinate
        routeStops.sort {
            let d0 = origin.distance(to: $0.coordinate.mapCoordinate)
            let d1 = origin.distance(to: $1.coordinate.mapCoordinate)
            return d0 < d1
        }
        normalizeCurrentStop()
        scheduleRouteSync()
    }

    func addWaypoint(title: String, near area: ChennaiArea, notes: String? = nil) {
        geocodeTask?.cancel()
        geocodeTask = Task {
            let coord = await VendorGeocodingService.shared.coordinate(placeName: title, near: area)
                ?? area.seedCoordinate
            guard !Task.isCancelled else { return }
            let now = Date()
            let arrival = Calendar.current.date(byAdding: .minute, value: 25, to: now) ?? now
            let depart = Calendar.current.date(byAdding: .minute, value: 45, to: now) ?? now
            routeStops.append(
                VendorRouteStopPlan(
                    id: "stop_\(UUID().uuidString)",
                    title: title,
                    neighborhood: area,
                    landmark: title,
                    coordinate: coord,
                    arrivalTime: arrival,
                    departureTime: depart,
                    isCompleted: false,
                    isCurrent: false,
                    estimatedInterest: 0,
                    notes: notes,
                    source: "manual"
                )
            )
            normalizeCurrentStop()
            scheduleRouteSync()
        }
    }

    func insertClusterAfterCurrent(_ cluster: DemandCluster) {
        addDemandCluster(cluster, insertAfterCurrent: true)
    }

    func addDemandCluster(_ cluster: DemandCluster, insertAfterCurrent: Bool = false) {
        let now = Date()
        let arrival = Calendar.current.date(byAdding: .minute, value: 20, to: now) ?? now
        let depart = Calendar.current.date(byAdding: .minute, value: 40, to: now) ?? now
        let stop = VendorRouteStopPlan(
            id: "demand_\(cluster.id)",
            title: cluster.neighborhoodName,
            neighborhood: cluster.neighborhood,
            landmark: cluster.productHints.first ?? cluster.neighborhoodName,
            coordinate: cluster.coordinate,
            arrivalTime: arrival,
            departureTime: depart,
            isCompleted: false,
            isCurrent: false,
            estimatedInterest: cluster.customerCount,
            notes: cluster.preferredTimeWindow,
            source: "demand"
        )

        if insertAfterCurrent, let currentIndex = routeStops.firstIndex(where: { $0.isCurrent && !$0.isCompleted }) {
            routeStops.insert(stop, at: currentIndex + 1)
        } else {
            routeStops.append(stop)
        }
        normalizeCurrentStop()
        scheduleRouteSync()
    }

    func addDemandStop(_ signal: VendorDemandSignal) {
        let now = Date()
        let arrival = Calendar.current.date(byAdding: .minute, value: 25, to: now) ?? now
        let depart = Calendar.current.date(byAdding: .minute, value: 40, to: now) ?? now
        routeStops.append(
            VendorRouteStopPlan(
                id: "adhoc_\(UUID().uuidString)",
                title: signal.title,
                neighborhood: signal.neighborhood,
                landmark: signal.subtitle,
                coordinate: signal.coordinate,
                arrivalTime: arrival,
                departureTime: depart,
                isCompleted: false,
                isCurrent: false,
                estimatedInterest: signal.customerCount,
                notes: signal.preferredTimeWindow,
                source: "signal"
            )
        )
        normalizeCurrentStop()
        scheduleRouteSync()
    }

    func deleteStop(_ stopID: String) {
        routeStops.removeAll { $0.id == stopID }
        normalizeCurrentStop()
        scheduleRouteSync()
    }

    func updateOperatingArea(_ area: ChennaiArea) {
        selectedOperatingArea = area
        VendorGeoContext.shared.selectArea(area, recenter: true)
        routeStops = VendorServiceModeDemoData.defaultStops(for: area)
        demandClusters = Self.demoClusters(for: area, category: vendorCategory)
        geocodeOperatingArea()
        geocodeRouteStops()
        updateLocationText()
        refreshRecommendations()
    }

    func applyVendorCategory(_ category: VendorCategory) {
        vendorCategory = category
        switch state {
        case .offline, .failed:
            serviceMode = Self.loadPreferredMode(for: vendorId) ?? category.defaultServiceMode
        case .preparing, .live, .stopping:
            break
        }
        demandClusters = Self.demoClusters(for: selectedOperatingArea, category: category)
        refreshRecommendations()
        if firebaseSession.isReady {
            demandRepository.startListening(vendorCategory: category.rawValue)
        }
    }

    func selectServiceMode(_ mode: VendorServiceMode) {
        serviceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.preferredModeKey(for: vendorId))
    }

    private static func preferredModeKey(for vendorId: String) -> String {
        "vendor.preferred_service_mode.\(vendorId)"
    }

    private static func loadPreferredMode(for vendorId: String) -> VendorServiceMode? {
        guard let raw = UserDefaults.standard.string(forKey: preferredModeKey(for: vendorId)) else { return nil }
        return VendorServiceMode(rawValue: raw)
    }

    func centerMapTarget() -> CodableCoordinate {
        resolvedAreaCoordinate()
    }

    private func bindDemandRepository() {
        demandRepository.$demandClusters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clusters in
                guard let self else { return }
                let scoped = clusters.filter { $0.neighborhood == self.selectedOperatingArea }
                self.demandClusters = scoped.isEmpty
                    ? Self.demoClusters(for: self.selectedOperatingArea, category: self.vendorCategory)
                    : scoped
                self.demandSignals = self.demandClusters.map { cluster in
                    VendorDemandSignal(
                        id: cluster.id,
                        title: "\(cluster.customerCount) customers · \(cluster.neighborhoodName)",
                        subtitle: cluster.productHints.joined(separator: ", "),
                        neighborhood: cluster.neighborhood,
                        coordinate: cluster.coordinate,
                        customerCount: cluster.customerCount,
                        signalType: cluster.signalTypes.first ?? .categoryInterest,
                        preferredTimeWindow: cluster.preferredTimeWindow,
                        category: self.vendorCategory
                    )
                }
                self.customerRequests = self.demandRepository.interestRequests
                self.refreshRecommendations()
            }
            .store(in: &cancellables)

        if firebaseSession.isReady {
            demandRepository.startListening(vendorCategory: vendorCategory.rawValue)
        } else {
            firebaseSession.$readiness
                .compactMap { readiness -> Bool? in
                    if case .ready = readiness { return true }
                    return nil
                }
                .first()
                .sink { [weak self] _ in
                    guard let self else { return }
                    self.demandRepository.startListening(vendorCategory: self.vendorCategory.rawValue)
                }
                .store(in: &cancellables)
        }
    }

    private func refreshRecommendations() {
        routeRecommendations = VendorDemandClusterEngine.recommendations(
            vendorLocation: currentCoordinate(),
            routeStops: routeStops,
            clusters: demandClusters
        )
        demandRepository.updateRecommendations(
            vendorLocation: currentCoordinate(),
            routeStops: routeStops
        )
    }

    private func geocodeOperatingArea() {
        geocodeTask?.cancel()
        geocodeTask = Task {
            let coord = await VendorGeocodingService.shared.coordinate(for: selectedOperatingArea)
            guard !Task.isCancelled else { return }
            geocodedAreaCoordinate = coord
        }
    }

    private func geocodeRouteStops() {
        Task {
            var updated = routeStops
            let center = selectedOperatingArea.seedCoordinate.mapCoordinate
            for index in updated.indices {
                let stop = updated[index]
                // Keep circuit return pinned to the start coordinate.
                if stop.source == "circuit_return", let first = updated.first {
                    updated[index].coordinate = first.coordinate
                    continue
                }
                guard let coord = await VendorGeocodingService.shared.coordinate(
                    placeName: stop.title,
                    near: stop.neighborhood
                ) else { continue }
                let meters = CLLocation(latitude: center.latitude, longitude: center.longitude)
                    .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                // Only accept geocodes that stay inside the neighborhood (~1.6 km).
                if meters < 1600 {
                    updated[index].coordinate = coord
                }
            }
            // Re-close loop after geocoding.
            if let first = updated.first,
               let returnIdx = updated.firstIndex(where: { $0.source == "circuit_return" }) {
                updated[returnIdx].coordinate = first.coordinate
            }
            routeStops = updated
            scheduleRouteSync()
        }
    }

    private func resolvedAreaCoordinate() -> CodableCoordinate {
        geocodedAreaCoordinate ?? selectedOperatingArea.seedCoordinate
    }

    private func scheduleRouteSync() {
        refreshRecommendations()
        guard state == .live else { return }
        routeSyncTask?.cancel()
        routeSyncTask = Task {
            try? await firebase.saveRoute(vendorID: vendorId, stops: routeStops)
        }
    }

    private static func demoClusters(for area: ChennaiArea, category: VendorCategory = .vegetables) -> [DemandCluster] {
        VendorServiceModeDemoData.demoDemandClusters(for: area, category: category)
    }

    func markStopCompleted(_ stopID: String) {
        routeStops = routeStops.map { stop in
            var changed = stop
            if stop.id == stopID {
                changed.isCompleted = true
                changed.isCurrent = false
            }
            return changed
        }
        normalizeCurrentStop()
        scheduleRouteSync()
    }

    func acceptRequest(_ id: String) {
        Task { await demandRepository.acceptRequest(id) }
    }

    func dismissRequest(_ id: String) {
        Task { await demandRepository.dismissRequest(id) }
    }

    func completeRequest(_ id: String) {
        Task { await demandRepository.completeRequest(id) }
    }

    func addRequestToRoute(_ request: CustomerInterestRequest) {
        let cluster = DemandCluster(
            id: request.id,
            neighborhoodId: request.neighborhoodId,
            neighborhoodName: request.neighborhood.localizedName,
            coordinate: request.approximateCoordinate,
            customerCount: 1,
            level: .low,
            categories: [request.vendorCategory],
            productHints: [request.productHint].compactMap { $0 },
            preferredTimeWindow: request.preferredTime,
            signalTypes: [.visitRequest]
        )
        addDemandCluster(cluster, insertAfterCurrent: true)
        Task { await demandRepository.acceptRequest(request.id) }
    }

    func skipStop(_ stopID: String) {
        routeStops.removeAll { $0.id == stopID }
        normalizeCurrentStop()
        scheduleRouteSync()
    }

    func reorderStops(from source: IndexSet, to destination: Int) {
        routeStops.move(fromOffsets: source, toOffset: destination)
        normalizeCurrentStop()
        scheduleRouteSync()
    }

    private func restorePersistedSessionIfNeeded() {
        guard let snapshot = VendorLiveSessionStore.load(for: vendorId), snapshot.isLive else { return }
        if let expires = snapshot.presenceExpiresAt, expires < Date() {
            VendorLiveSessionStore.clear()
            return
        }
        serviceMode = snapshot.serviceMode
        selectedOperatingArea = snapshot.operatingArea
        liveStartedAt = snapshot.startedAt
        presenceExpiresAt = snapshot.presenceExpiresAt
        presenceConfirmedAt = snapshot.presenceConfirmedAt
        if let started = snapshot.startedAt {
            liveElapsedSeconds = max(0, Int(Date().timeIntervalSince(started)))
        }
        state = .live
        startLiveClockTask()
        startPresenceWatchTask()
        scheduleBroadcastIfNeeded()
    }

    private func persistLiveSession(isLive: Bool) {
        if isLive {
            VendorLiveSessionStore.save(
                VendorLiveSessionStore.Snapshot(
                    vendorID: vendorId,
                    isLive: true,
                    startedAt: liveStartedAt,
                    serviceMode: serviceMode,
                    operatingArea: selectedOperatingArea,
                    presenceExpiresAt: presenceExpiresAt,
                    presenceConfirmedAt: presenceConfirmedAt
                )
            )
        } else {
            VendorLiveSessionStore.clear()
        }
    }

    private func persistAnnouncement() {
        guard let announcement else { return }
        VendorAnnouncementStore.save(announcement, for: vendorId)
    }

    private func normalizeCurrentStop() {
        var seenCurrent = false
        for idx in routeStops.indices {
            if routeStops[idx].isCompleted {
                routeStops[idx].isCurrent = false
                continue
            }
            if !seenCurrent {
                routeStops[idx].isCurrent = true
                seenCurrent = true
            } else {
                routeStops[idx].isCurrent = false
            }
        }
    }

    private func updateLocationText() {
        switch serviceMode {
        case .mobile:
            currentLocationText = VendorMockData.locationLabel(for: selectedOperatingArea)
        case .stationary:
            currentLocationText = "\(selectedOperatingArea.localizedName) · \(stationaryLandmark)"
        case .scheduled:
            if let current = routeStops.first(where: { $0.isCurrent && !$0.isCompleted }) {
                currentLocationText = current.landmark
            } else {
                currentLocationText = VendorMockData.locationLabel(for: selectedOperatingArea)
            }
        }
    }

    private func performPrepareSequence() async {
        defer {
            if Task.isCancelled, state == .preparing {
                state = .offline
            }
        }

        // Go LIVE on-device immediately — never wait on Firebase.
        guard !Task.isCancelled else { return }
        liveStartedAt = Date()
        liveElapsedSeconds = 0
        let interval = serviceMode.presenceCheckIntervalMinutes
        presenceConfirmedAt = Date()
        presenceExpiresAt = Date().addingTimeInterval(Double(interval) * 60)
        showPresencePrompt = false
        updateLocationText()
        state = .live
        persistLiveSession(isLive: true)
        startLiveClockTask()
        startPresenceWatchTask()
        scheduleBroadcastIfNeeded()

        // Cloud sync in the background. Timeout → warning only, stay live.
        let syncTask = Task { [weak self] in
            await self?.syncLiveToFirebaseWithTimeout(seconds: 8)
        }
        _ = syncTask
    }

    private func syncLiveToFirebaseWithTimeout(seconds: Double) async {
        let work = Task { () -> String? in
            do {
                try await firebaseSession.ensureReadyForWrites()
                try await firebase.setLive(
                    vendorID: vendorId,
                    isLive: true,
                    serviceMode: serviceMode,
                    operatingArea: selectedOperatingArea,
                    landmark: currentLandmark(),
                    coordinate: currentCoordinate(),
                    presenceExpiresAt: presenceExpiresAt,
                    presenceConfirmedAt: presenceConfirmedAt,
                    presenceCheckIntervalMinutes: serviceMode.presenceCheckIntervalMinutes
                )
                try await firebase.saveRoute(vendorID: vendorId, stops: routeStops)
                return nil
            } catch {
                return error.localizedDescription
            }
        }

        enum Race {
            case finished(String?)
            case timedOut
        }

        let outcome = await withTaskGroup(of: Race.self) { group -> Race in
            group.addTask {
                .finished(await work.value)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return .timedOut
            }
            let first = await group.next() ?? .timedOut
            group.cancelAll()
            return first
        }

        switch outcome {
        case .finished(let error):
            errorMessage = error.map { "You are live. Cloud sync failed: \($0)" }
        case .timedOut:
            errorMessage = "You are live. Still updating customers…"
            if let lateError = await work.value {
                errorMessage = "You are live. Cloud sync failed: \(lateError)"
            } else {
                errorMessage = nil
            }
        }
    }

    private func performStopSequence() async {
        defer {
            if Task.isCancelled, state == .stopping {
                state = .live
            }
        }

        do {
            try await firebaseSession.ensureReadyForWrites()
            let coordinate = currentCoordinate()
            try await firebase.setLive(
                vendorID: vendorId,
                isLive: false,
                serviceMode: serviceMode,
                operatingArea: selectedOperatingArea,
                landmark: currentLandmark(),
                coordinate: coordinate
            )
        } catch {
            errorMessage = "Stopped locally. Cloud sync may be delayed."
        }

        guard !Task.isCancelled else { return }
        broadcastTask?.cancel()
        timerTask?.cancel()
        presenceTask?.cancel()
        nextBroadcastAt = nil
        liveStartedAt = nil
        liveElapsedSeconds = 0
        presenceExpiresAt = nil
        presenceConfirmedAt = nil
        showPresencePrompt = false
        state = .offline
        persistLiveSession(isLive: false)
    }

    private func currentCoordinate() -> CodableCoordinate {
        if let current = routeStops.first(where: { $0.isCurrent && !$0.isCompleted }) {
            return current.coordinate
        }
        return resolvedAreaCoordinate()
    }

    private func currentLandmark() -> String {
        switch serviceMode {
        case .stationary:
            return stationaryLandmark
        case .scheduled:
            return routeStops.first(where: { $0.isCurrent && !$0.isCompleted })?.landmark ?? stationaryLandmark
        case .mobile:
            return VendorMockData.locationLabel(for: selectedOperatingArea)
        }
    }

    private func scheduleBroadcastIfNeeded() {
        broadcastTask?.cancel()
        nextBroadcastAt = nil

        guard state == .live,
              let minutes = broadcastIntervalMinutes,
              minutes > 0,
              !isBroadcastPaused,
              announcement?.vendorBroadcastEnabled == true else {
            return
        }

        broadcastTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let next = Date().addingTimeInterval(Double(minutes) * 60)
                await MainActor.run { self.nextBroadcastAt = next }
                try? await Task.sleep(nanoseconds: UInt64(minutes) * 60_000_000_000)
                guard !Task.isCancelled else { break }
                NotificationCenter.default.post(name: .vendorPlayAnnouncementNow, object: nil)
            }
        }
    }

    private func startLiveClockTask() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    guard let started = self.liveStartedAt else { return }
                    self.liveElapsedSeconds = max(0, Int(Date().timeIntervalSince(started)))
                }
            }
        }
    }

    private func startPresenceWatchTask() {
        presenceTask?.cancel()
        guard serviceMode.requiresPresenceConfirmation else {
            showPresencePrompt = false
            return
        }
        presenceTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    guard self.state == .live, let expires = self.presenceExpiresAt else { return }
                    let remaining = expires.timeIntervalSinceNow
                    if remaining <= 0 {
                        self.errorMessage = "Presence expired. Going offline."
                        self.stopLive()
                    } else if remaining <= 10 * 60 {
                        self.showPresencePrompt = true
                    }
                }
            }
        }
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b)
    }
}

extension Notification.Name {
    static let vendorPlayAnnouncementNow = Notification.Name("vendor.playAnnouncementNow")
}
