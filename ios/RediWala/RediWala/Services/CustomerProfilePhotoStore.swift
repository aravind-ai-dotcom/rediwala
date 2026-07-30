import Foundation
import UIKit

/// Local customer profile photo persistence (DEBUG/demo-friendly).
enum CustomerProfilePhotoStore {
    private static let keyPrefix = "customer.profile.photo.path."

    static func loadPath(for customerID: String) -> String? {
        guard let path = UserDefaults.standard.string(forKey: keyPrefix + customerID),
              FileManager.default.fileExists(atPath: path) else { return nil }
        return path
    }

    @discardableResult
    static func save(_ image: UIImage, for customerID: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
        let url = fileURL(for: customerID)
        do {
            try data.write(to: url, options: .atomic)
            UserDefaults.standard.set(url.path, forKey: keyPrefix + customerID)
            return url.path
        } catch {
            return nil
        }
    }

    static func remove(for customerID: String) {
        if let path = loadPath(for: customerID) {
            try? FileManager.default.removeItem(atPath: path)
        }
        UserDefaults.standard.removeObject(forKey: keyPrefix + customerID)
    }

    private static func fileURL(for customerID: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CustomerPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(customerID).jpg")
    }
}
