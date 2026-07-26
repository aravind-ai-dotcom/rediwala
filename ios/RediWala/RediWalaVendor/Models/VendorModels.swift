import Foundation

enum VendorLiveStatus: Equatable {
    case offline
    case live
}

struct VendorDaySummary: Equatable {
    var salesRupees: Int
    var customers: Int
    var hours: Double
}

struct VendorProfile: Equatable {
    var name: String
    var language: String
    var phone: String
    var category: String
    var workingHours: String
}

enum VendorTab: Hashable {
    case home
    case inventory
    case earnings
    case profile
}
