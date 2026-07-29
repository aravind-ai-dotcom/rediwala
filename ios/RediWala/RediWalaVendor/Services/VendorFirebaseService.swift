import FirebaseDatabase
import FirebaseStorage
import Foundation

@MainActor
final class VendorFirebaseService {
    static let shared = VendorFirebaseService()

    private let session = VendorFirebaseSession.shared
    private let storage = Storage.storage()

    private init() {}

    func setLive(
        vendorID: String,
        isLive: Bool,
        serviceMode: VendorServiceMode,
        operatingArea: ChennaiArea,
        landmark: String,
        coordinate: CodableCoordinate,
        presenceExpiresAt: Date? = nil,
        presenceConfirmedAt: Date? = nil,
        presenceCheckIntervalMinutes: Int? = nil
    ) async throws {
        try await session.ensureReadyForWrites()
        let db = session.root
        let now = ISO8601DateFormatter().string(from: Date())
        let requiresConfirmation = serviceMode != .mobile

        var status: [String: Any] = [
            "vendorId": vendorID,
            "sellerId": vendorID,
            "isLive": isLive,
            "serviceMode": serviceMode.rawValue,
            "lastSeen": now,
            "startedAt": isLive ? now : NSNull(),
            "availabilityTextEn": isLive ? "Live nearby now" : "Offline — see My Day",
            "availabilityTextTa": isLive ? "இப்போது அருகில் நேரலை" : "ஆஃப்லைன் — இன்றைய பயணத்தைப் பாருங்கள்",
            "isPresenceConfirmationRequired": requiresConfirmation,
            "lastLocationUpdateAt": now
        ]

        if isLive {
            let interval = presenceCheckIntervalMinutes ?? serviceMode.presenceCheckIntervalMinutes
            let confirmed = presenceConfirmedAt ?? Date()
            let expires = presenceExpiresAt ?? confirmed.addingTimeInterval(Double(interval) * 60)
            status["presenceConfirmedAt"] = ISO8601DateFormatter().string(from: confirmed)
            status["presenceExpiresAt"] = ISO8601DateFormatter().string(from: expires)
            status["presenceCheckIntervalMinutes"] = interval
            status["scheduledClosingTime"] = ISO8601DateFormatter().string(from: expires)
        } else {
            status["presenceConfirmedAt"] = NSNull()
            status["presenceExpiresAt"] = NSNull()
            status["presenceCheckIntervalMinutes"] = NSNull()
            status["scheduledClosingTime"] = NSNull()
        }

        let location: [String: Any] = [
            "vendorId": vendorID,
            "sellerId": vendorID,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "landmarkEn": landmark,
            "landmark": landmark,
            "neighborhoodId": firebaseNeighborhoodID(for: operatingArea),
            "updatedAt": now,
            "declaredLatitude": coordinate.latitude,
            "declaredLongitude": coordinate.longitude
        ]

        do {
            try await db.child(VendorRTDBPath.vendorStatus(vendorID)).setValue(status)
            try await db.child(VendorRTDBPath.vendorLocation(vendorID)).setValue(location)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    /// Extends / refreshes presence without changing offline/online semantics beyond remaining live.
    func confirmPresence(
        vendorID: String,
        serviceMode: VendorServiceMode,
        operatingArea: ChennaiArea,
        landmark: String,
        coordinate: CodableCoordinate,
        extendByMinutes: Int
    ) async throws {
        let confirmed = Date()
        let expires = confirmed.addingTimeInterval(Double(extendByMinutes) * 60)
        try await setLive(
            vendorID: vendorID,
            isLive: true,
            serviceMode: serviceMode,
            operatingArea: operatingArea,
            landmark: landmark,
            coordinate: coordinate,
            presenceExpiresAt: expires,
            presenceConfirmedAt: confirmed,
            presenceCheckIntervalMinutes: extendByMinutes
        )
    }

    func saveRoute(vendorID: String, stops: [VendorRouteStopPlan]) async throws {
        try await session.ensureReadyForWrites()
        let db = session.root

        var stopPayload: [String: Any] = [:]
        for (index, stop) in stops.enumerated() {
            let status: String
            if stop.isCompleted { status = "completed" }
            else if stop.isCurrent { status = "current" }
            else { status = "upcoming" }

            stopPayload[stop.id] = [
                "id": stop.id,
                "sequence": index + 1,
                "time": formattedTime(stop.arrivalTime),
                "titleEn": stop.title,
                "title": stop.title,
                "neighborhoodId": firebaseNeighborhoodID(for: stop.neighborhood),
                "latitude": stop.coordinate.latitude,
                "longitude": stop.coordinate.longitude,
                "status": status
            ]
        }

        let route: [String: Any] = [
            "vendorId": vendorID,
            "routeDate": todayString(),
            "stops": stopPayload
        ]

        do {
            try await db.child(VendorRTDBPath.vendorRoute(vendorID)).setValue(route)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func saveAnnouncement(_ draft: VendorAnnouncementDraft, vendorID: String) async throws -> VendorAnnouncementDraft {
        try await session.ensureReadyForWrites()
        let db = session.root
        var updated = draft

        if let localPath = draft.localFilePath,
           let data = FileManager.default.contents(atPath: localPath) {
            let path = "announcements/dev/\(vendorID)/\(draft.id).m4a"
            let metadata = StorageMetadata()
            metadata.contentType = "audio/mp4"
            _ = try await storage.reference(withPath: path).putDataAsync(data, metadata: metadata)
            updated.storagePath = path
        }

        let payload: [String: Any] = [
            "vendorId": vendorID,
            "sellerId": vendorID,
            "duration": draft.durationSeconds,
            "language": draft.language,
            "storagePath": updated.storagePath as Any,
            "recordedAt": ISO8601DateFormatter().string(from: draft.recordedAt),
            "transcriptEnglish": draft.transcriptPlaceholder,
            "transcriptTamil": draft.transcriptPlaceholder,
            "playbackIntervalMinutes": draft.playbackIntervalMinutes as Any,
            "hasAnnouncement": true,
            "activeWhileLive": draft.activeWhileLive,
            "customerPlaybackEnabled": draft.customerPlaybackEnabled,
            "vendorBroadcastEnabled": draft.vendorBroadcastEnabled
        ]

        do {
            try await db.child(VendorRTDBPath.vendorAnnouncement(vendorID)).setValue(payload)
        } catch {
            throw mapFirebaseError(error)
        }
        return updated
    }

    func uploadProfilePhoto(_ imageData: Data, vendorID: String) async throws -> String {
        try await session.ensureReadyForWrites()
        let db = session.root
        let path = "vendor_photos/dev/\(vendorID)/profile.jpg"
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await storage.reference(withPath: path).putDataAsync(imageData, metadata: metadata)
        let url = try await storage.reference(withPath: path).downloadURL().absoluteString
        do {
            try await db.child(VendorRTDBPath.vendor(vendorID)).updateChildValues(["photoURL": url])
        } catch {
            throw mapFirebaseError(error)
        }
        return url
    }

    private func mapFirebaseError(_ error: Error) -> Error {
        let nsError = error as NSError
        let message = nsError.localizedDescription.lowercased()
        if message.contains("permission_denied") || message.contains("permission denied") {
            return VendorFirebaseError.permissionDenied
        }
        return VendorFirebaseError.writeFailed(error.localizedDescription)
    }

    private func firebaseNeighborhoodID(for area: ChennaiArea) -> String {
        area.firebaseID
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
