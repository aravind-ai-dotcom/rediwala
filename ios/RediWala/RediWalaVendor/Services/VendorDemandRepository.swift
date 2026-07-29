import Combine
import FirebaseDatabase
import Foundation

@MainActor
final class VendorDemandRepository: ObservableObject {
    @Published private(set) var interestRequests: [CustomerInterestRequest] = []
    @Published private(set) var demandClusters: [DemandCluster] = []
    @Published private(set) var routeRecommendations: [RouteRecommendation] = []

    private let session = VendorFirebaseSession.shared
    private var handle: DatabaseHandle?
    private var isListening = false
    private var vendorCategory: String = "vegetables"

    func startListening(vendorCategory: String) {
        guard !isListening else { return }
        self.vendorCategory = vendorCategory
        isListening = true

        let ref = session.root.child(VendorRTDBPath.customerInterest)
        handle = ref.observe(.value) { [weak self] snapshot in
            Task { @MainActor [weak self] in
                self?.applySnapshot(snapshot)
            }
        }

        if let cached: [CustomerInterestRequest] = VendorLocalJSONCache.load([CustomerInterestRequest].self, key: VendorCacheKeys.demandClusters) {
            interestRequests = cached
            recompute()
        }
    }

    func stopListening() {
        if let handle {
            session.root.child(VendorRTDBPath.customerInterest).removeObserver(withHandle: handle)
        }
        handle = nil
        isListening = false
    }

    func updateRecommendations(
        vendorLocation: CodableCoordinate,
        routeStops: [VendorRouteStopPlan]
    ) {
        routeRecommendations = VendorDemandClusterEngine.recommendations(
            vendorLocation: vendorLocation,
            routeStops: routeStops,
            clusters: demandClusters
        )
    }

    func acceptRequest(_ id: String) async {
        await updateStatus(id, status: .accepted)
    }

    func dismissRequest(_ id: String) async {
        await updateStatus(id, status: .dismissed)
    }

    func completeRequest(_ id: String) async {
        await updateStatus(id, status: .completed)
    }

    private func applySnapshot(_ snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String: Any] else {
            interestRequests = []
            demandClusters = []
            return
        }

        var parsed: [CustomerInterestRequest] = []
        for (key, value) in dict {
            guard let payload = value as? [String: Any] else { continue }
            if let request = mapRequest(id: key, payload: payload) {
                parsed.append(request)
            }
        }

        interestRequests = parsed
            .filter { $0.vendorCategory == vendorCategory || vendorCategory.isEmpty }
            .sorted { $0.createdAt > $1.createdAt }

        VendorLocalJSONCache.save(interestRequests, key: VendorCacheKeys.demandClusters)
        recompute()
    }

    private func recompute() {
        demandClusters = VendorDemandClusterEngine.cluster(requests: interestRequests)
    }

    private func updateStatus(_ id: String, status: InterestRequestStatus) async {
        do {
            try await session.ensureReadyForWrites()
            try await session.root
                .child(VendorRTDBPath.customerInterest(id))
                .updateChildValues(["status": status.rawValue])
        } catch {
            // Best-effort; local list updates on next snapshot.
        }
    }

    private func mapRequest(id: String, payload: [String: Any]) -> CustomerInterestRequest? {
        guard let customerId = payload["customerId"] as? String,
              let category = payload["vendorCategory"] as? String,
              let neighborhoodId = payload["neighborhoodId"] as? String,
              let typeRaw = payload["requestType"] as? String,
              let requestType = CustomerInterestType(rawValue: typeRaw),
              let statusRaw = payload["status"] as? String,
              let status = InterestRequestStatus(rawValue: statusRaw) else {
            return nil
        }

        let lat = payload["latitude"] as? Double ?? ChennaiArea.fromFirebaseID(neighborhoodId).seedCoordinate.latitude
        let lng = payload["longitude"] as? Double ?? ChennaiArea.fromFirebaseID(neighborhoodId).seedCoordinate.longitude
        let createdAt: Date
        if let ts = payload["createdAt"] as? String {
            createdAt = ISO8601DateFormatter().date(from: ts) ?? Date()
        } else {
            createdAt = Date()
        }

        return CustomerInterestRequest(
            id: id,
            customerId: customerId,
            vendorCategory: category,
            neighborhoodId: neighborhoodId,
            approximateCoordinate: CodableCoordinate(latitude: lat, longitude: lng),
            requestType: requestType,
            preferredTime: payload["preferredTime"] as? String,
            productHint: payload["productHint"] as? String,
            createdAt: createdAt,
            status: status,
            urgencyScore: payload["urgencyScore"] as? Int ?? 1
        )
    }
}
