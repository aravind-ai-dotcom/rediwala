import Foundation

enum VendorRTDBPath {
    static let vendors = "vendors"
    static let vendorStatus = "vendor_status"
    static let vendorLocations = "vendor_locations"
    static let vendorRoutes = "vendor_routes"
    static let vendorAnnouncements = "vendor_announcements"
    static let customerInterest = "customer_interest"
    static let vendorTransactions = "vendor_transactions"

    static func vendor(_ id: String) -> String { "\(vendors)/\(id)" }
    static func vendorStatus(_ id: String) -> String { "\(vendorStatus)/\(id)" }
    static func vendorLocation(_ id: String) -> String { "\(vendorLocations)/\(id)" }
    static func vendorRoute(_ id: String) -> String { "\(vendorRoutes)/\(id)" }
    static func vendorAnnouncement(_ id: String) -> String { "\(vendorAnnouncements)/\(id)" }
    static func customerInterest(_ id: String) -> String { "\(customerInterest)/\(id)" }
    static func vendorTransactions(_ vendorID: String) -> String { "\(vendorTransactions)/\(vendorID)" }
}
