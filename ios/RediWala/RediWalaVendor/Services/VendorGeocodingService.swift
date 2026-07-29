import CoreLocation
import Foundation
import MapKit

/// Geocodes Chennai neighborhoods and landmarks with disk cache. Never blocks the main thread.
actor VendorGeocodingService {
    static let shared = VendorGeocodingService()

    private var memoryCache: [String: CodableCoordinate] = [:]
    private let cacheKey = VendorCacheKeys.geocode

    private init() {
        if let cached: [String: CodableCoordinate] = VendorLocalJSONCache.load([String: CodableCoordinate].self, key: cacheKey) {
            memoryCache = cached
        }
    }

    func coordinate(for area: ChennaiArea) async -> CodableCoordinate {
        await coordinate(forQuery: area.geocodeQuery, cacheKey: "area_\(area.rawValue)", near: area)
    }

    func coordinate(placeName: String, near area: ChennaiArea? = nil) async -> CodableCoordinate? {
        let suffix = area.map { ", \($0.geocodeQuery)" } ?? ", Chennai, Tamil Nadu, India"
        let query = "\(placeName)\(suffix)"
        return await coordinate(forQuery: query, cacheKey: "place_\(placeName.lowercased())_\(area?.rawValue ?? "chennai")", near: area)
    }

    func coordinate(forQuery query: String, cacheKey key: String, near area: ChennaiArea? = nil) async -> CodableCoordinate {
        if let cached = memoryCache[key] { return cached }

        let resolved = await resolve(query: query, near: area) ?? fallbackCoordinate(for: key)
        memoryCache[key] = resolved
        VendorLocalJSONCache.save(memoryCache, key: cacheKey)
        return resolved
    }

    private func resolve(query: String, near area: ChennaiArea? = nil) async -> CodableCoordinate? {
        let center = area?.seedCoordinate.mapCoordinate
            ?? CLLocationCoordinate2D(latitude: 13.05, longitude: 80.24)
        let spanDelta = area?.neighborhoodMapSpan ?? 0.012

        return await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
            )

            MKLocalSearch(request: request).start { response, _ in
                guard let item = response?.mapItems.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let coord = item.location.coordinate
                continuation.resume(returning: CodableCoordinate(latitude: coord.latitude, longitude: coord.longitude))
            }
        }
    }

    private func fallbackCoordinate(for key: String) -> CodableCoordinate {
        if key.hasPrefix("area_") {
            let raw = String(key.dropFirst(5))
            if let area = ChennaiArea(rawValue: raw) {
                return area.seedCoordinate
            }
        }
        return ChennaiArea.tNagar.seedCoordinate
    }
}
