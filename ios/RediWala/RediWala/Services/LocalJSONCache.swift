import Foundation

/// Disk cache for offline reads after the first successful Firebase sync.
enum LocalJSONCache {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("RediWalaCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: directory.appendingPathComponent(key + ".json"), options: .atomic)
        } catch {
            // Cache writes are best-effort.
        }
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let url = directory.appendingPathComponent(key + ".json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum CacheKeys {
    static let sellers = "sellers_v1"
    static let categories = "categories_v1"
    static let categoryGroups = "category_groups_v1"
    static let customerProfile = "customer_profile_v1"
    static let favorites = "favorites_v1"
    static let announcements = "announcements_v1"
    static let recentlyViewed = "recently_viewed_v1"
}
