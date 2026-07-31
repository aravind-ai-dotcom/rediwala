import FirebaseStorage
import Foundation
import UIKit

/// Local customer profile photo + Firebase Storage sync.
enum CustomerProfilePhotoStore {
    private static let keyPrefix = "customer.profile.photo.path."
    private static let pendingUploadPrefix = "customer.profile.photo.pending."

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
            markPendingUpload(true, for: customerID)
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
        markPendingUpload(false, for: customerID)
    }

    static func hasPendingUpload(for customerID: String) -> Bool {
        UserDefaults.standard.bool(forKey: pendingUploadPrefix + customerID)
    }

    static func markPendingUpload(_ pending: Bool, for customerID: String) {
        if pending {
            UserDefaults.standard.set(true, forKey: pendingUploadPrefix + customerID)
        } else {
            UserDefaults.standard.removeObject(forKey: pendingUploadPrefix + customerID)
        }
    }

    static func jpegData(for customerID: String) -> Data? {
        guard let path = loadPath(for: customerID) else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    private static func fileURL(for customerID: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CustomerPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(customerID).jpg")
    }
}

extension FirebaseStorageService {
    static func uploadCustomerProfilePhoto(data: Data, customerID: String) async throws -> String {
        let path = "customer_photos/dev/\(customerID)/profile.jpg"
        _ = try await upload(data: data, to: path, contentType: "image/jpeg")
        let url = try await Storage.storage().reference(withPath: path).downloadURL()
        return url.absoluteString
    }
}
