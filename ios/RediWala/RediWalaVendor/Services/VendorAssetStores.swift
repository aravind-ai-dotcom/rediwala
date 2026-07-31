import Foundation
import UIKit

/// Vendor media lives in Application Support so iOS won't purge it like Caches.
enum VendorMediaDirectory {
    static func root() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("RediWalaVendor", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

enum VendorProfilePhotoStore {
    private static let defaultsKeyPrefix = "vendor.photo.path."
    private static let pendingPrefix = "vendor.photo.pending."

    static func loadPath(for vendorID: String) -> String? {
        if let path = UserDefaults.standard.string(forKey: defaultsKeyPrefix + vendorID),
           FileManager.default.fileExists(atPath: path) {
            return path
        }
        // Migrate legacy Caches path if still present.
        let legacy = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("vendor_photos/\(vendorID).jpg")
        if let legacy, FileManager.default.fileExists(atPath: legacy.path),
           let data = try? Data(contentsOf: legacy),
           let image = UIImage(data: data) {
            return save(image, for: vendorID)
        }
        return nil
    }

    static func save(_ image: UIImage, for vendorID: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.78) else { return nil }
        let directory = VendorMediaDirectory.root().appendingPathComponent("photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("\(vendorID).jpg")
        do {
            try data.write(to: path, options: .atomic)
            UserDefaults.standard.set(path.path, forKey: defaultsKeyPrefix + vendorID)
            markPending(true, for: vendorID)
            return path.path
        } catch {
            return nil
        }
    }

    static func remove(for vendorID: String) {
        if let existing = loadPath(for: vendorID) {
            try? FileManager.default.removeItem(atPath: existing)
        }
        UserDefaults.standard.removeObject(forKey: defaultsKeyPrefix + vendorID)
        markPending(false, for: vendorID)
    }

    static func jpegData(for vendorID: String) -> Data? {
        guard let path = loadPath(for: vendorID) else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    static func hasPendingUpload(for vendorID: String) -> Bool {
        UserDefaults.standard.bool(forKey: pendingPrefix + vendorID)
    }

    static func markPending(_ pending: Bool, for vendorID: String) {
        if pending {
            UserDefaults.standard.set(true, forKey: pendingPrefix + vendorID)
        } else {
            UserDefaults.standard.removeObject(forKey: pendingPrefix + vendorID)
        }
    }
}

enum VendorAnnouncementStore {
    private static let keyPrefix = "vendor.announcement."
    private static let pendingPrefix = "vendor.announcement.pending."

    static func save(_ draft: VendorAnnouncementDraft, for vendorID: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(draft) {
            UserDefaults.standard.set(data, forKey: keyPrefix + vendorID)
        }
        if draft.storagePath == nil {
            markPending(true, for: vendorID)
        } else {
            markPending(false, for: vendorID)
        }
    }

    static func load(for vendorID: String) -> VendorAnnouncementDraft? {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + vendorID) else { return nil }
        return try? JSONDecoder().decode(VendorAnnouncementDraft.self, from: data)
    }

    static func hasPendingUpload(for vendorID: String) -> Bool {
        UserDefaults.standard.bool(forKey: pendingPrefix + vendorID)
    }

    static func markPending(_ pending: Bool, for vendorID: String) {
        if pending {
            UserDefaults.standard.set(true, forKey: pendingPrefix + vendorID)
        } else {
            UserDefaults.standard.removeObject(forKey: pendingPrefix + vendorID)
        }
    }

    static func audioURL(for vendorID: String) -> URL {
        let directory = VendorMediaDirectory.root().appendingPathComponent("announcements", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(vendorID)_announcement.m4a")
    }
}

/// Persists today's offerings + prep checklist so they survive restart.
enum VendorBusinessDayStore {
    private static func key(_ vendorID: String, _ suffix: String) -> String {
        "vendor.day.\(vendorID).\(suffix)"
    }

    static func saveOfferings(_ items: [VendorInventoryItem], vendorID: String) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key(vendorID, "offerings"))
    }

    static func loadOfferings(vendorID: String, category: VendorCategory) -> [VendorInventoryItem] {
        if let data = UserDefaults.standard.data(forKey: key(vendorID, "offerings")),
           let items = try? JSONDecoder().decode([VendorInventoryItem].self, from: data),
           !items.isEmpty {
            return items
        }
        return VendorMockData.offerings(for: category)
    }

    static func savePrep(
        inventoryReady: Bool,
        hoursConfirmed: Bool,
        openMinutes: Int,
        closeMinutes: Int,
        vendorID: String
    ) {
        UserDefaults.standard.set(inventoryReady, forKey: key(vendorID, "inventoryReady"))
        UserDefaults.standard.set(hoursConfirmed, forKey: key(vendorID, "hoursConfirmed"))
        UserDefaults.standard.set(openMinutes, forKey: key(vendorID, "openMinutes"))
        UserDefaults.standard.set(closeMinutes, forKey: key(vendorID, "closeMinutes"))
        UserDefaults.standard.set(Self.dayStamp(), forKey: key(vendorID, "day"))
    }

    static func loadPrep(vendorID: String) -> (inventoryReady: Bool, hoursConfirmed: Bool, open: Int, close: Int)? {
        guard UserDefaults.standard.string(forKey: key(vendorID, "day")) == dayStamp() else {
            return nil
        }
        return (
            UserDefaults.standard.bool(forKey: key(vendorID, "inventoryReady")),
            UserDefaults.standard.bool(forKey: key(vendorID, "hoursConfirmed")),
            UserDefaults.standard.object(forKey: key(vendorID, "openMinutes")) as? Int ?? 8 * 60,
            UserDefaults.standard.object(forKey: key(vendorID, "closeMinutes")) as? Int ?? 13 * 60
        )
    }

    private static func dayStamp() -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}