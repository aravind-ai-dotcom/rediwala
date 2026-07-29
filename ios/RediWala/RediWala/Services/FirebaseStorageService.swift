import FirebaseStorage
import Foundation

enum FirebaseStorageService {
    private static let storage = Storage.storage()

    static func downloadURL(forStoragePath path: String) async -> URL? {
        do {
            return try await storage.reference(withPath: path).downloadURL()
        } catch {
            return nil
        }
    }

    static func upload(data: Data, to path: String, contentType: String) async throws -> String {
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        _ = try await storage.reference(withPath: path).putDataAsync(data, metadata: metadata)
        return path
    }
}
