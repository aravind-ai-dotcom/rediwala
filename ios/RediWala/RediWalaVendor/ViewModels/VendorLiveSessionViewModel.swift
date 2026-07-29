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

    init(vendorId: String) {
        self.vendorId = vendorId
        self.announcement = VendorAnnouncementStore.load(for: vendorId)
        self.profilePhotoLocalPath = VendorProfilePhotoStore.loadPath(for: vendorId)
        if let interval = announcement?.playbackIntervalMinutes {
            broadcastIntervalMinutes = interval
        }
        restorePersistedSessionIfNeeded()
        updateLocationText()
        geocodeOperatingArea()
        geocodeRouteStops()
        bindDemandRepository()

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

    var vendorCategory: VendorCategory {
        .vegetables
    }

    var isFirebaseReady: Bool {
        firebaseSession.isReady
    }

    var canStartLive: Bool {
        guard firebaseSession.isReady else { return false }
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
        persistAnnouncement()
        scheduleBroadcastIfNeeded()
        guard let draft else { return }
        announcementUploadTask?.cancel()
        announcementUploadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let synced = try await self.firebase.saveAnnouncement(draft, vendorID: self.vendorId)
                guard !Task.isCancelled else { return }
                self.announcement = synced
                self.persistAnnouncement()
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = "Announcement saved locally. Cloud sync will retry later."
            }
        }
    }

    func setProfilePhotoPath(_ path: String?) {
        profilePhotoLocalPath = path
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
        routeStops = VendorServiceModeDemoData.defaultStops(for: area)
        geocodeOperatingArea()
        geocodeRouteStops()
        updateLocationText()
    }

    func centerMapTarget() -> CodableCoordinate {
        resolvedAreaCoordinate()
    }

    private func bindDemandRepository() {
        demandRepository.$demandClusters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clusters in
                guard let self else { return }
                let base = clusters.isEmpty ? Self.demoClusters(for: self.selectedOperatingArea) : clusters
                self.demandClusters = base.filter {
                    $0.neighborhood == self.selectedOperatingArea
                }
                self.demandSignals = clusters.map { cluster in
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
            for index in updated.indices {
                let stop = updated[index]
                if let coord = await VendorGeocodingService.shared.coordinate(placeName: stop.title, near: stop.neighborhood) {
                    updated[index].coordinate = coord
                }
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

    private static func demoClusters(for area: ChennaiArea) -> [DemandCluster] {
        VendorServiceModeDemoData.demandSignals.map { signal in
            DemandCluster(
                id: signal.id,
                neighborhoodId: area.firebaseID,
                neighborhoodName: String(localized: String.LocalizationValue(area.labelKey)),
                coordinate: signal.coordinate,
                customerCount: signal.customerCount,
                level: DemandLevel.from(customerCount: signal.customerCount),
                categories: [signal.category.rawValue],
                productHints: [signal.subtitle],
                preferredTimeWindow: signal.preferredTimeWindow,
                signalTypes: [signal.signalType]
            )
        }
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
            neighborhoodName: String(localized: String.LocalizationValue(request.neighborhood.labelKey)),
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
            currentLocationText = "\(String(localized: String.LocalizationValue(selectedOperatingArea.labelKey))) · \(stationaryLandmark)"
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
