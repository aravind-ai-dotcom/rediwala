import CoreLocation
import Foundation

/// Scopes seller lists to GeoContext — never city-wide dumps for recommendations.
enum GeoScopedQuery {
    static func filter(
        sellers: [Seller],
        scope: GeoQueryScope,
        needsCategories: Set<SellerCategory> = []
    ) -> [Seller] {
        sellers
            .filter { seller in
                let withinRadius = CLLocation(
                    latitude: seller.latitude,
                    longitude: seller.longitude
                ).distance(
                    from: CLLocation(latitude: scope.center.latitude, longitude: scope.center.longitude)
                ) <= scope.radiusMeters

                let neighborhoodMatch = FirebaseIDMap.firebaseID(for: seller.neighborhood) == scope.neighborhoodId
                    || withinRadius

                guard neighborhoodMatch && withinRadius else { return false }

                if !needsCategories.isEmpty {
                    guard needsCategories.contains(seller.category) else { return false }
                } else if !scope.categoryRawValues.isEmpty {
                    let suggested = Set(scope.categoryRawValues)
                    let categoryID = FirebaseIDMap.firebaseID(for: seller.category)
                    // Soft prefer economy categories; still allow exact neighborhood vendors.
                    _ = suggested.contains(categoryID)
                }

                switch scope.availability {
                case .any: return true
                case .liveOnly: return seller.isEffectivelyLive
                case .expectedSoon: return !seller.isEffectivelyLive
                }
            }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    static func adjustDistances(_ sellers: [Seller], using context: GeoContext) -> [Seller] {
        sellers.map { seller in
            let meters = context.distanceMeters(
                toLatitude: seller.latitude,
                longitude: seller.longitude
            )
            return seller.with(distanceMeters: meters)
        }
    }
}
