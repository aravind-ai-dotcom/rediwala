import CoreLocation
import Foundation
import MapKit

/// Builds road-following polylines between waypoints using MKDirections. Results are cached.
@MainActor
final class VendorRouteDirectionService {
    static let shared = VendorRouteDirectionService()

    private var polylineCache: [String: [CodableCoordinate]] = [:]
    private var activeTask: Task<Void, Never>?

    private init() {
        polylineCache = VendorLocalJSONCache.load([String: [CodableCoordinate]].self, key: VendorCacheKeys.routePolylines) ?? [:]
    }

    func polyline(for stops: [VendorRouteStopPlan]) async -> [CodableCoordinate] {
        let activeStops = stops.filter { !$0.isCompleted }
        guard activeStops.count >= 2 else {
            return activeStops.map(\.coordinate)
        }

        let cacheKey = activeStops.map { "\($0.id):\($0.coordinate.latitude),\($0.coordinate.longitude)" }.joined(separator: "|")
        if let cached = polylineCache[cacheKey] { return cached }

        var merged: [CodableCoordinate] = []
        for index in 0..<(activeStops.count - 1) {
            let from = activeStops[index].coordinate.mapCoordinate
            let to = activeStops[index + 1].coordinate.mapCoordinate
            let segment = await fetchSegment(from: from, to: to)
            if merged.isEmpty {
                merged.append(contentsOf: segment)
            } else if let first = segment.first, let last = merged.last,
                      first.latitude == last.latitude, first.longitude == last.longitude {
                merged.append(contentsOf: segment.dropFirst())
            } else {
                merged.append(contentsOf: segment)
            }
        }

        polylineCache[cacheKey] = merged
        VendorLocalJSONCache.save(polylineCache, key: VendorCacheKeys.routePolylines)
        return merged
    }

    func refresh(for stops: [VendorRouteStopPlan], onUpdate: @escaping ([CodableCoordinate]) -> Void) {
        activeTask?.cancel()
        activeTask = Task {
            let line = await polyline(for: stops)
            guard !Task.isCancelled else { return }
            onUpdate(line)
        }
    }

    private func fetchSegment(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> [CodableCoordinate] {
        await withCheckedContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(location: CLLocation(latitude: from.latitude, longitude: from.longitude), address: nil)
            request.destination = MKMapItem(location: CLLocation(latitude: to.latitude, longitude: to.longitude), address: nil)
            request.transportType = .automobile

            MKDirections(request: request).calculate { response, _ in
                if let polyline = response?.routes.first?.polyline {
                    let coords = polyline.coordinates
                    continuation.resume(returning: coords.map { CodableCoordinate(latitude: $0.latitude, longitude: $0.longitude) })
                } else {
                    continuation.resume(returning: [
                        CodableCoordinate(latitude: from.latitude, longitude: from.longitude),
                        CodableCoordinate(latitude: to.latitude, longitude: to.longitude)
                    ])
                }
            }
        }
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var result: [CLLocationCoordinate2D] = []
        let points = self.points()
        for index in 0..<pointCount {
            result.append(points[index].coordinate)
        }
        return result
    }
}
