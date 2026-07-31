import FirebaseAuth
import Foundation

enum DemoUserRole: String, Codable, Equatable {
    case customer
    case vendor
}

/// Catalog of synthetic demo accounts. Passwords compile only in DEBUG.
enum DemoAuthCatalog {
    struct Account: Identifiable, Equatable {
        var id: String { email }
        let email: String
        let displayName: String
        let shortLabel: String
        let role: DemoUserRole
        let vendorId: String?
        #if DEBUG
        let demoPassword: String
        #endif
    }

    static let customers: [Account] = [
        make(email: "meena@demo.rediwala", displayName: "Meena Krishnan", short: "Meena · West Mambalam", role: .customer, vendorId: nil, password: "Meena123!"),
        make(email: "sundaram@demo.rediwala", displayName: "Sundaram Iyer", short: "Sundaram · T. Nagar", role: .customer, vendorId: nil, password: "Sundaram123!"),
        make(email: "priya@demo.rediwala", displayName: "Priya Narayanan", short: "Priya · Adyar", role: .customer, vendorId: nil, password: "Priya123!"),
        make(email: "lakshmi.home@demo.rediwala", displayName: "Lakshmi Household", short: "Lakshmi · Thiruvanmiyur", role: .customer, vendorId: nil, password: "Lakshmi123!"),
        make(email: "ravi.apartment@demo.rediwala", displayName: "Ravi Apartments", short: "Ravi · Velachery", role: .customer, vendorId: nil, password: "Ravi123!"),
    ]

    static let vendors: [Account] = [
        make(email: "murugan@demo.rediwala", displayName: "Murugan Fresh Vegetables", short: "Murugan · Vegetables", role: .vendor, vendorId: "murugan", password: "Murugan123!"),
        make(email: "lakshmi.flowers@demo.rediwala", displayName: "Lakshmi Flowers and Garlands", short: "Lakshmi · Flowers", role: .vendor, vendorId: "lakshmi", password: "Flowers123!"),
        make(email: "siva.ironing@demo.rediwala", displayName: "Siva Ironing and Clothing Repairs", short: "Siva · Ironing", role: .vendor, vendorId: "siva_ironing", password: "Ironing123!"),
        make(email: "babu.laundry@demo.rediwala", displayName: "Babu Laundry Pickup", short: "Babu · Laundry", role: .vendor, vendorId: "babu_laundry", password: "Laundry123!"),
        make(email: "kumar.cable@demo.rediwala", displayName: "Kumar Cable Collection Service", short: "Kumar · Cable", role: .vendor, vendorId: "kumar_cable", password: "Cable123!"),
    ]

    private static func make(
        email: String,
        displayName: String,
        short: String,
        role: DemoUserRole,
        vendorId: String?,
        password: String
    ) -> Account {
        #if DEBUG
        return Account(email: email, displayName: displayName, shortLabel: short, role: role, vendorId: vendorId, demoPassword: password)
        #else
        return Account(email: email, displayName: displayName, shortLabel: short, role: role, vendorId: vendorId)
        #endif
    }
}
