import FirebaseAuth
import FirebaseDatabase
import Foundation

struct DemoUserProfile: Equatable {
    var uid: String
    var email: String
    var role: DemoUserRole
    var displayName: String
    var preferredLanguage: String
    var profileCompleted: Bool
    var isDemoAccount: Bool
    var vendorId: String?
}

struct DemoCustomerProfile: Equatable {
    var homeNeighborhood: String
    var homeAreaLabel: String?
    var todaysNeeds: [String]
    var followedVendorIds: [String]
    var savedVendorIds: [String]
    var apartmentMetadata: [String: String]
    var preferredLanguage: String?
}

/// Loads/writes `users/{uid}` and role-specific profile trees. Never stores passwords.
@MainActor
final class DemoUserProfileService {
    static let shared = DemoUserProfileService()

    private var database: Database {
        FirebaseDatabaseConfig.database
    }

    func fetchUserProfile(uid: String) async throws -> DemoUserProfile? {
        let snapshot = try await database.reference().child("users").child(uid).getData()
        guard let value = snapshot.value as? [String: Any] else { return nil }
        guard let roleRaw = value["role"] as? String,
              let role = DemoUserRole(rawValue: roleRaw),
              let email = value["email"] as? String else {
            return nil
        }
        return DemoUserProfile(
            uid: uid,
            email: email,
            role: role,
            displayName: value["displayName"] as? String ?? "",
            preferredLanguage: value["preferredLanguage"] as? String ?? "en",
            profileCompleted: value["profileCompleted"] as? Bool ?? false,
            isDemoAccount: value["isDemoAccount"] as? Bool ?? false,
            vendorId: value["vendorId"] as? String
        )
    }

    func fetchCustomerProfile(uid: String) async throws -> DemoCustomerProfile? {
        let snapshot = try await database.reference().child("customers").child(uid).getData()
        guard let value = snapshot.value as? [String: Any] else { return nil }
        var apartment: [String: String] = [:]
        if let meta = value["apartmentMetadata"] as? [String: Any] {
            for (key, raw) in meta {
                apartment[key] = "\(raw)"
            }
        }
        return DemoCustomerProfile(
            homeNeighborhood: value["homeNeighborhood"] as? String ?? "west_mambalam",
            homeAreaLabel: value["homeAreaLabel"] as? String,
            todaysNeeds: value["todaysNeeds"] as? [String] ?? [],
            followedVendorIds: value["followedVendorIds"] as? [String] ?? [],
            savedVendorIds: value["savedVendorIds"] as? [String] ?? [],
            apartmentMetadata: apartment,
            preferredLanguage: value["preferredLanguage"] as? String
        )
    }

    func requireRole(_ expected: DemoUserRole, for uid: String) async throws -> DemoUserProfile {
        guard let profile = try await fetchUserProfile(uid: uid) else {
            throw DemoAuthProfileError.missingProfile
        }
        guard profile.role == expected else {
            throw DemoAuthProfileError.wrongRole(actual: profile.role)
        }
        return profile
    }
}

enum DemoAuthProfileError: LocalizedError {
    case missingProfile
    case wrongRole(actual: DemoUserRole)

    var errorDescription: String? {
        switch self {
        case .missingProfile:
            return String(localized: "auth.error.missing_profile")
        case .wrongRole(let actual):
            switch actual {
            case .vendor:
                return String(localized: "auth.error.vendor_in_customer_app")
            case .customer:
                return String(localized: "auth.error.customer_in_vendor_app")
            }
        }
    }
}
