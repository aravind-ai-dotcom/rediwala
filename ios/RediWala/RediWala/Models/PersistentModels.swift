import CoreLocation
import Foundation

/// Persistent customer profile used across launches (anonymous device identity).
struct PersistentCustomerProfile: Equatable, Codable, Identifiable {
    var id: String
    var displayName: String
    var preferredLanguage: AppLanguage
    var selectedNeighborhood: PilotNeighborhood
    var favoriteCategories: [SellerCategory]
    var favorites: [String]
    var createdDate: Date
    var lastSeen: Date
    var photoURL: String?
    var cityId: String
    var phone: String?

    var areaKey: String { selectedNeighborhood.nameKey }

    static func makeNew(id: String, language: AppLanguage = .english) -> PersistentCustomerProfile {
        let now = Date()
        return PersistentCustomerProfile(
            id: id,
            displayName: "Neighbor",
            preferredLanguage: language,
            selectedNeighborhood: .tNagar,
            favoriteCategories: [],
            favorites: [],
            createdDate: now,
            lastSeen: now,
            photoURL: nil,
            cityId: "chennai",
            phone: nil
        )
    }
}

struct CachedAnnouncement: Equatable, Codable, Identifiable {
    var id: String
    var vendorId: String
    var duration: Int
    var language: String
    var storagePath: String?
    var transcriptEnglish: String?
    var transcriptTamil: String?
    var playbackIntervalMinutes: Int
    var hasAnnouncement: Bool
}

struct CachedCategoryRecord: Equatable, Codable, Identifiable {
    var id: String
    var groupFirebaseId: String
    var nameEn: String
    var nameTa: String
    var sfSymbol: String
    var enabled: Bool
    var comingSoon: Bool
    var displayOrder: Int

    var sellerCategory: SellerCategory? {
        FirebaseIDMap.sellerCategory(fromFirebase: id)
    }
}

struct CachedCategoryGroupRecord: Equatable, Codable, Identifiable {
    var id: String
    var nameEn: String
    var nameTa: String
    var displayOrder: Int
    var enabled: Bool

    var group: CategoryGroup? {
        FirebaseIDMap.categoryGroup(fromFirebase: id)
    }
}

/// Codable snapshot of a seller for disk cache / offline.
struct CachedSeller: Equatable, Codable, Identifiable {
    var id: String
    var name: String
    var businessName: String?
    var categoryRaw: String
    var profileImageAssetName: String?
    var neighborhoodRaw: String
    var landmarkKey: String
    var latitude: Double
    var longitude: Double
    var isLive: Bool
    var distanceMeters: Int
    var directionKey: String
    var rating: Double
    var languagesRaw: [String]
    var hasAnnouncement: Bool
    var announcementDurationSeconds: Int
    var announcementStoragePath: String?
    var routeStops: [RouteStop]
    var workingHours: String
    var descriptionKey: String
    var phone: String
    var photoURL: String?

    func asSeller(near neighborhood: PilotNeighborhood? = nil) -> Seller? {
        guard let category = SellerCategory(rawValue: categoryRaw),
              let hood = PilotNeighborhood(rawValue: neighborhoodRaw) else {
            return nil
        }
        var distance = distanceMeters
        if let neighborhood {
            distance = SellerDistance.meters(
                from: neighborhood.coordinate,
                toLatitude: latitude,
                toLongitude: longitude
            )
        }
        return Seller(
            id: id,
            name: name,
            businessName: businessName,
            category: category,
            profileImageAssetName: profileImageAssetName,
            neighborhood: hood,
            landmarkKey: landmarkKey,
            latitude: latitude,
            longitude: longitude,
            isLive: isLive,
            distanceMeters: distance,
            directionKey: directionKey,
            rating: rating,
            languages: languagesRaw.compactMap(AppLanguage.init(rawValue:)),
            hasAnnouncement: hasAnnouncement,
            announcementDurationSeconds: announcementDurationSeconds,
            announcementStoragePath: announcementStoragePath,
            routeStops: routeStops,
            workingHours: workingHours,
            descriptionKey: descriptionKey,
            phone: phone,
            photoURL: photoURL,
            serviceMode: SellerCategory(rawValue: categoryRaw)?.defaultServiceMode ?? .mobile,
            progressLabel: nil,
            apartmentComplex: nil,
            streetName: nil,
            todaysMessagePreview: hasAnnouncement ? "Today's message available" : nil,
            etaLabel: isLive ? "Nearby now" : nil
        )
    }

    static func from(_ seller: Seller) -> CachedSeller {
        CachedSeller(
            id: seller.id,
            name: seller.name,
            businessName: seller.businessName,
            categoryRaw: seller.category.rawValue,
            profileImageAssetName: seller.profileImageAssetName,
            neighborhoodRaw: seller.neighborhood.rawValue,
            landmarkKey: seller.landmarkKey,
            latitude: seller.latitude,
            longitude: seller.longitude,
            isLive: seller.isLive,
            distanceMeters: seller.distanceMeters,
            directionKey: seller.directionKey,
            rating: seller.rating,
            languagesRaw: seller.languages.map(\.rawValue),
            hasAnnouncement: seller.hasAnnouncement,
            announcementDurationSeconds: seller.announcementDurationSeconds,
            announcementStoragePath: seller.announcementStoragePath,
            routeStops: seller.routeStops,
            workingHours: seller.workingHours,
            descriptionKey: seller.descriptionKey,
            phone: seller.phone,
            photoURL: seller.photoURL
        )
    }
}

enum SellerDistance {
    static func meters(
        from origin: CLLocationCoordinate2D,
        toLatitude: Double,
        toLongitude: Double
    ) -> Int {
        let a = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let b = CLLocation(latitude: toLatitude, longitude: toLongitude)
        return Int(a.distance(from: b))
    }
}
