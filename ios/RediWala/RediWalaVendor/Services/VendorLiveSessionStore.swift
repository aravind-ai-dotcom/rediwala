import Foundation

/// Local persistence so a live session survives brief app backgrounding during the demo sprint.
enum VendorLiveSessionStore {
    private static let key = "vendor.live.session.snapshot"

    struct Snapshot: Codable, Equatable {
        var vendorID: String
        var isLive: Bool
        var startedAt: Date?
        var serviceMode: VendorServiceMode
        var operatingArea: ChennaiArea
        var presenceExpiresAt: Date?
        var presenceConfirmedAt: Date?
    }

    static func save(_ snapshot: Snapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load(for vendorID: String) -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data),
              snapshot.vendorID == vendorID else {
            return nil
        }
        return snapshot
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
