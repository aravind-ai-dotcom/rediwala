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

@MainActor
final class DemoUserProfileService {
    static let shared = DemoUserProfileService()

    private var root: DatabaseReference {
        VendorFirebaseSession.shared.root
    }

    func fetchUserProfile(uid: String) async throws -> DemoUserProfile? {
        let snapshot = try await root.child("users").child(uid).getData()
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
