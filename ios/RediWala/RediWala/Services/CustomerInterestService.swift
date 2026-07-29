import CoreLocation
import FirebaseDatabase
import Foundation

/// Customer-side interest requests. Coordinates are jittered — never exact home locations.
enum CustomerInterestService {
    private static var db: DatabaseReference { FirebaseDatabaseConfig.root }

    enum RequestType: String, CaseIterable, Identifiable {
        case interested
        case comeToMyArea
        case needToday
        case needProduct
        case comeThisEvening

        var id: String { rawValue }

        var titleKey: String { "interest.\(rawValue)" }
    }

    static func submit(
        customerID: String,
        vendorCategory: String,
        neighborhood: PilotNeighborhood,
        type: RequestType,
        productHint: String? = nil,
        preferredTime: String? = nil
    ) async throws {
        FirebaseDatabaseConfig.configureIfNeeded()
        let requestID = UUID().uuidString
        let approximate = jitteredCoordinate(neighborhood.coordinate)

        let payload: [String: Any] = [
            "requestId": requestID,
            "customerId": customerID,
            "vendorCategory": vendorCategory,
            "neighborhoodId": FirebaseIDMap.firebaseID(for: neighborhood),
            "latitude": approximate.latitude,
            "longitude": approximate.longitude,
            "requestType": type.rawValue,
            "preferredTime": preferredTime as Any,
            "productHint": productHint as Any,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "status": "open",
            "urgencyScore": urgency(for: type)
        ]

        try await db.child(FirebaseRTDBPath.customerInterest(requestID)).setValue(payload)
    }

    private static func urgency(for type: RequestType) -> Int {
        switch type {
        case .needToday, .needProduct: return 3
        case .comeThisEvening: return 2
        default: return 1
        }
    }

    /// Offset within ~200–400 m so clusters show approximate areas only.
    private static func jitteredCoordinate(_ center: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let latOffset = Double.random(in: -0.003...0.003)
        let lngOffset = Double.random(in: -0.003...0.003)
        return CLLocationCoordinate2D(
            latitude: center.latitude + latOffset,
            longitude: center.longitude + lngOffset
        )
    }
}
