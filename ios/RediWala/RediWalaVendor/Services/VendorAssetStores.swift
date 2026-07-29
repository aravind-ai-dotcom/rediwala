import Foundation
import UIKit

enum VendorProfilePhotoStore {
    private static let defaultsKeyPrefix = "vendor.photo.path."

    static func loadPath(for vendorID: String) -> String? {
        UserDefaults.standard.string(forKey: defaultsKeyPrefix + vendorID)
    }

    static func save(_ image: UIImage, for vendorID: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.78) else { return nil }
        let directory = cacheDirectory().appendingPathComponent("vendor_photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("\(vendorID).jpg")
        do {
            try data.write(to: path, options: .atomic)
            UserDefaults.standard.set(path.path, forKey: defaultsKeyPrefix + vendorID)
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
    }

    private static func cacheDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
    }
}

enum VendorAnnouncementStore {
    private static let keyPrefix = "vendor.announcement."

    static func save(_ draft: VendorAnnouncementDraft, for vendorID: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(draft) {
            UserDefaults.standard.set(data, forKey: keyPrefix + vendorID)
        }
    }

    static func load(for vendorID: String) -> VendorAnnouncementDraft? {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + vendorID) else { return nil }
        return try? JSONDecoder().decode(VendorAnnouncementDraft.self, from: data)
    }
}
