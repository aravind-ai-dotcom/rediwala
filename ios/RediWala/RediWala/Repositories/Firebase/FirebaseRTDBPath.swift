import Foundation

enum FirebaseRTDBPath {
    static let metadata = "metadata"
    static let cities = "cities"
    static let neighborhoods = "neighborhoods"
    static let categoryGroups = "categoryGroups"
    static let categories = "categories"
    static let vendors = "vendors"
    static let vendorStatus = "vendor_status"
    static let vendorLocations = "vendor_locations"
    static let vendorRoutes = "vendor_routes"
    static let vendorAnnouncements = "vendor_announcements"
    static let customers = "customers"
    static let customerFavorites = "customer_favorites"
    static let customerSettings = "customer_settings"
    static let customerInterest = "customer_interest"
    static let users = "users"
    static let customerRequests = "customerRequests"
    static let vendorLiveSessions = "vendorLiveSessions"

    static func vendor(_ id: String) -> String { "\(vendors)/\(id)" }
    static func vendorStatus(_ id: String) -> String { "\(vendorStatus)/\(id)" }
    static func vendorLocation(_ id: String) -> String { "\(vendorLocations)/\(id)" }
    static func vendorRoute(_ id: String) -> String { "\(vendorRoutes)/\(id)" }
    static func vendorAnnouncement(_ id: String) -> String { "\(vendorAnnouncements)/\(id)" }
    static func customer(_ id: String) -> String { "\(customers)/\(id)" }
    static func user(_ id: String) -> String { "\(users)/\(id)" }
    static func customerFavorites(_ id: String) -> String { "\(customerFavorites)/\(id)" }
    static func customerFavorite(customerId: String, vendorId: String) -> String {
        "\(customerFavorites)/\(customerId)/\(vendorId)"
    }
    static func customerSettings(_ id: String) -> String { "\(customerSettings)/\(id)" }
    static func customerInterest(_ id: String) -> String { "\(customerInterest)/\(id)" }
}
