import Foundation

// MARK: - Customer Interest

enum CustomerInterestType: String, Codable, CaseIterable, Identifiable {
    case interested
    case comeToMyArea
    case needToday
    case needProduct
    case comeThisEvening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interested: return "I'm interested"
        case .comeToMyArea: return "Come to my area"
        case .needToday: return "Need this today"
        case .needProduct: return "Need specific product"
        case .comeThisEvening: return "Come this evening"
        }
    }

    var systemImage: String {
        switch self {
        case .interested: return "hand.thumbsup.fill"
        case .comeToMyArea: return "mappin.and.ellipse"
        case .needToday: return "calendar.badge.clock"
        case .needProduct: return "cart.fill"
        case .comeThisEvening: return "moon.stars.fill"
        }
    }
}

enum InterestRequestStatus: String, Codable {
    case open
    case accepted
    case dismissed
    case completed
}

struct CustomerInterestRequest: Identifiable, Codable, Equatable {
    let id: String
    var customerId: String
    var vendorCategory: String
    var neighborhoodId: String
    var approximateCoordinate: CodableCoordinate
    var requestType: CustomerInterestType
    var preferredTime: String?
    var productHint: String?
    var createdAt: Date
    var status: InterestRequestStatus
    var urgencyScore: Int

    var neighborhood: ChennaiArea {
        ChennaiArea.fromFirebaseID(neighborhoodId)
    }
}

// MARK: - Demand Clusters

enum DemandLevel: String, Codable, CaseIterable, Hashable {
    case high
    case medium
    case low

    /// Plain language for vendors — no "demand level" jargon.
    var titleKey: String {
        switch self {
        case .high: return "demand.lots_waiting"
        case .medium: return "demand.some_waiting"
        case .low: return "demand.few_waiting"
        }
    }

    var emoji: String {
        switch self {
        case .high: return "🙋"
        case .medium: return "👋"
        case .low: return "👤"
        }
    }

    func peopleWaiting(count: Int) -> String {
        String(format: String(localized: "demand.people_waiting_count"), count)
    }

    static func from(customerCount: Int) -> DemandLevel {
        if customerCount >= 8 { return .high }
        if customerCount >= 4 { return .medium }
        return .low
    }
}

struct DemandCluster: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var neighborhoodId: String
    var neighborhoodName: String
    var coordinate: CodableCoordinate
    var customerCount: Int
    var level: DemandLevel
    var categories: [String]
    var productHints: [String]
    var preferredTimeWindow: String?
    var signalTypes: [DemandSignalType]

    var neighborhood: ChennaiArea {
        ChennaiArea.fromFirebaseID(neighborhoodId)
    }

    var peopleWaitingText: String {
        String(format: String(localized: "demand.people_waiting_count"), customerCount)
    }
}

// MARK: - Route Recommendations

struct RouteRecommendation: Identifiable, Equatable, Hashable {
    let id: String
    var message: String
    var clusterID: String?
    var bearingHint: String?
    var distanceMeters: Int?
}

// MARK: - Clustering Engine

enum VendorDemandClusterEngine {
    static func cluster(requests: [CustomerInterestRequest]) -> [DemandCluster] {
        let open = requests.filter { $0.status == .open }
        guard !open.isEmpty else { return [] }

        var groups: [String: [CustomerInterestRequest]] = [:]
        for request in open {
            let key = "\(request.neighborhoodId)_\(request.vendorCategory)"
            groups[key, default: []].append(request)
        }

        return groups.map { key, items in
            let neighborhoodId = items.first?.neighborhoodId ?? "t_nagar"
            let area = ChennaiArea.fromFirebaseID(neighborhoodId)
            let avgLat = items.map(\.approximateCoordinate.latitude).reduce(0, +) / Double(items.count)
            let avgLng = items.map(\.approximateCoordinate.longitude).reduce(0, +) / Double(items.count)
            let count = items.count
            let products = Array(Set(items.compactMap(\.productHint).filter { !$0.isEmpty }))
            let categories = Array(Set(items.map(\.vendorCategory)))
            let times = items.compactMap(\.preferredTime).filter { !$0.isEmpty }
            let types = Array(Set(items.map { mapType($0.requestType) }))

            return DemandCluster(
                id: "cluster_\(key)",
                neighborhoodId: neighborhoodId,
                neighborhoodName: String(localized: String.LocalizationValue(area.labelKey)),
                coordinate: CodableCoordinate(latitude: avgLat, longitude: avgLng),
                customerCount: count,
                level: DemandLevel.from(customerCount: count),
                categories: categories,
                productHints: products,
                preferredTimeWindow: times.first,
                signalTypes: types
            )
        }
        .sorted { $0.customerCount > $1.customerCount }
    }

    static func recommendations(
        vendorLocation: CodableCoordinate,
        routeStops: [VendorRouteStopPlan],
        clusters: [DemandCluster]
    ) -> [RouteRecommendation] {
        guard !clusters.isEmpty else { return [] }

        var results: [RouteRecommendation] = []
        let vendorCoord = vendorLocation.mapCoordinate

        for cluster in clusters.prefix(3) {
            let distance = Int(vendorCoord.distance(to: cluster.coordinate.mapCoordinate))
            let bearing = bearingDescription(from: vendorCoord, to: cluster.coordinate.mapCoordinate)
            let message = String(
                format: String(localized: "demand.tip.nearby"),
                cluster.customerCount,
                cluster.neighborhoodName,
                formattedDistance(distance),
                bearing
            )
            results.append(RouteRecommendation(
                id: "rec_\(cluster.id)",
                message: message,
                clusterID: cluster.id,
                bearingHint: bearing,
                distanceMeters: distance
            ))
        }

        if let favorites = clusters.first(where: { $0.signalTypes.contains(.favoriteNearby) }) {
            results.append(RouteRecommendation(
                id: "rec_fav_\(favorites.id)",
                message: String(
                    format: String(localized: "demand.tip.favorites"),
                    favorites.customerCount,
                    favorites.neighborhoodName
                ),
                clusterID: favorites.id,
                distanceMeters: Int(vendorCoord.distance(to: favorites.coordinate.mapCoordinate))
            ))
        }

        if let nextStop = routeStops.first(where: { $0.isCurrent && !$0.isCompleted }),
           let nearStop = clusters.min(by: {
               $0.coordinate.mapCoordinate.distance(to: nextStop.coordinate.mapCoordinate)
                   < $1.coordinate.mapCoordinate.distance(to: nextStop.coordinate.mapCoordinate)
           }) {
            results.append(RouteRecommendation(
                id: "rec_near_stop",
                message: String(
                    format: String(localized: "demand.tip.next_stop"),
                    nearStop.customerCount
                ),
                clusterID: nearStop.id
            ))
        }

        return Array(results.prefix(5))
    }

    private static func mapType(_ type: CustomerInterestType) -> DemandSignalType {
        switch type {
        case .interested, .needToday, .needProduct: return .categoryInterest
        case .comeToMyArea: return .visitRequest
        case .comeThisEvening: return .recentDemand
        }
    }

    private static func bearingDescription(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> String {
        let deltaLat = to.latitude - from.latitude
        let deltaLng = to.longitude - from.longitude
        let absLat = abs(deltaLat)
        let absLng = abs(deltaLng)
        if absLat > absLng {
            return deltaLat > 0 ? "north" : "south"
        }
        return deltaLng > 0 ? "east" : "west"
    }

    private static func formattedDistance(_ meters: Int) -> String {
        if meters >= 1000 { return String(format: "%.1f km", Double(meters) / 1000) }
        return "\(meters)m"
    }
}

import CoreLocation

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
