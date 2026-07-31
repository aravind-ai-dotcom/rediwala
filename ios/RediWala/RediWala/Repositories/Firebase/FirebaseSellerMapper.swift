import CoreLocation
import Foundation

enum FirebaseSellerMapper {
    static func mapSeller(
        id: String,
        vendor: [String: Any],
        status: [String: Any]?,
        location: [String: Any]?,
        route: [String: Any]?,
        announcement: [String: Any]?,
        near neighborhood: PilotNeighborhood
    ) -> Seller? {
        guard let category = FirebaseIDMap.sellerCategory(fromFirebase: vendor["categoryId"] as? String) else {
            return nil
        }

        let hood = FirebaseIDMap.neighborhood(fromFirebase: vendor["neighborhoodId"] as? String)
        let lat = (location?["latitude"] as? Double)
            ?? (location?["latitude"] as? NSNumber)?.doubleValue
            ?? neighborhood.coordinate.latitude
        let lng = (location?["longitude"] as? Double)
            ?? (location?["longitude"] as? NSNumber)?.doubleValue
            ?? neighborhood.coordinate.longitude

        let landmark = (location?["landmarkEn"] as? String)
            ?? (location?["landmark"] as? String)
            ?? hood.nameKey

        let isLiveFlag = (status?["isLive"] as? Bool) ?? false
        let presenceExpiresAt = FirebaseRTDBHelpers.date(from: status?["presenceExpiresAt"])
        let isLive: Bool = {
            guard isLiveFlag else { return false }
            if let expires = presenceExpiresAt, expires < Date() { return false }
            return true
        }()
        let rating = ((vendor["ratingSummary"] as? [String: Any])?["average"] as? Double)
            ?? ((vendor["ratingSummary"] as? [String: Any])?["average"] as? NSNumber)?.doubleValue
            ?? 4.5

        let languageCodes = (vendor["languages"] as? [String]) ?? ["ta", "en"]
        let languages = languageCodes.compactMap { AppLanguage(rawValue: $0) }

        let hours = vendor["workingHours"] as? [String: Any]
        let workingLabel = (hours?["labelEn"] as? String)
            ?? {
                let start = hours?["start"] as? String ?? "06:00"
                let end = hours?["end"] as? String ?? "20:00"
                return "\(start) – \(end)"
            }()

        let description = (vendor["descriptionEnglish"] as? String)
            ?? (vendor["descriptionTamil"] as? String)
            ?? ""

        let hasAnnouncement = (announcement?["hasAnnouncement"] as? Bool) ?? false
        let duration = (announcement?["duration"] as? Int)
            ?? (announcement?["duration"] as? NSNumber)?.intValue
            ?? 0
        let storagePath = announcement?["storagePath"] as? String

        let distance = SellerDistance.meters(
            from: neighborhood.coordinate,
            toLatitude: lat,
            toLongitude: lng
        )

        return Seller(
            id: id,
            name: (vendor["displayName"] as? String) ?? id,
            businessName: vendor["businessName"] as? String,
            category: category,
            profileImageAssetName: nil,
            neighborhood: hood,
            landmarkKey: landmark,
            latitude: lat,
            longitude: lng,
            isLive: isLive,
            distanceMeters: distance,
            directionKey: "direction.nearby",
            rating: rating,
            languages: languages.isEmpty ? [.tamil, .english] : languages,
            hasAnnouncement: hasAnnouncement,
            announcementDurationSeconds: duration,
            announcementStoragePath: storagePath,
            routeStops: mapRouteStops(route),
            workingHours: workingLabel,
            descriptionKey: description,
            phone: (vendor["phone"] as? String) ?? "",
            photoURL: vendor["photoURL"] as? String,
            serviceMode: CustomerServiceMode(rawValue: (status?["serviceMode"] as? String) ?? "")
                ?? category.defaultServiceMode,
            progressLabel: status?["progressLabel"] as? String,
            apartmentComplex: location?["apartmentComplex"] as? String,
            streetName: location?["streetName"] as? String,
            todaysMessagePreview: (announcement?["transcriptEnglish"] as? String),
            etaLabel: Self.etaLabel(
                isLive: isLive,
                distanceMeters: distance,
                presenceExpiresAt: presenceExpiresAt
            ),
            presenceExpiresAt: presenceExpiresAt
        )
    }

    private static func etaLabel(isLive: Bool, distanceMeters: Int, presenceExpiresAt: Date?) -> String? {
        if isLive {
            let minutes = max(3, min(45, distanceMeters / 40))
            if distanceMeters < 180 { return "Around the corner" }
            return "\(minutes) min"
        }
        if let presenceExpiresAt, presenceExpiresAt > Date() {
            let minutes = max(5, Int(presenceExpiresAt.timeIntervalSinceNow / 60))
            return "\(minutes) min"
        }
        return nil
    }

    static func mapRouteStops(_ route: [String: Any]?) -> [RouteStop] {
        guard let stopsMap = route?["stops"] as? [String: [String: Any]] else { return [] }
        let sorted = stopsMap.values.sorted {
            let a = ($0["sequence"] as? Int) ?? ($0["sequence"] as? NSNumber)?.intValue ?? 0
            let b = ($1["sequence"] as? Int) ?? ($1["sequence"] as? NSNumber)?.intValue ?? 0
            return a < b
        }
        return sorted.compactMap { stop in
            guard let id = stop["id"] as? String else { return nil }
            let statusRaw = (stop["status"] as? String) ?? "upcoming"
            let status = RouteStopStatus(rawValue: statusRaw) ?? .upcoming
            let title = (stop["titleEn"] as? String) ?? (stop["title"] as? String) ?? id
            let landmark = title
            let lat = (stop["latitude"] as? Double) ?? (stop["latitude"] as? NSNumber)?.doubleValue ?? 0
            let lng = (stop["longitude"] as? Double) ?? (stop["longitude"] as? NSNumber)?.doubleValue ?? 0
            return RouteStop(
                id: id,
                timeLabel: (stop["time"] as? String) ?? "",
                titleKey: title,
                neighborhood: FirebaseIDMap.neighborhood(fromFirebase: stop["neighborhoodId"] as? String),
                landmarkKey: landmark,
                latitude: lat,
                longitude: lng,
                status: status
            )
        }
    }

    static func mapAnnouncement(vendorId: String, value: [String: Any]) -> CachedAnnouncement {
        CachedAnnouncement(
            id: vendorId,
            vendorId: vendorId,
            duration: (value["duration"] as? Int) ?? (value["duration"] as? NSNumber)?.intValue ?? 0,
            language: (value["language"] as? String) ?? "ta",
            storagePath: value["storagePath"] as? String,
            transcriptEnglish: value["transcriptEnglish"] as? String,
            transcriptTamil: value["transcriptTamil"] as? String,
            playbackIntervalMinutes: (value["playbackIntervalMinutes"] as? Int)
                ?? (value["playbackIntervalMinutes"] as? NSNumber)?.intValue
                ?? 15,
            hasAnnouncement: (value["hasAnnouncement"] as? Bool) ?? false
        )
    }
}
