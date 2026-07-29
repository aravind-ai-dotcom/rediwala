import Foundation

/// Disk cache for vendor-side offline data (geocoding, routes, billing).
/// Nonisolated so background actors (e.g. geocoding) can read/write without hopping to MainActor.
nonisolated enum VendorLocalJSONCache {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("RediWalaVendorCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: directory.appendingPathComponent(key + ".json"), options: .atomic)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let url = directory.appendingPathComponent(key + ".json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

nonisolated enum VendorCacheKeys {
    static let geocode = "geocode_v1"
    static let routePolylines = "route_polylines_v1"
    static let billingTransactions = "billing_transactions_v1"
    static let demandClusters = "demand_clusters_v1"
}
