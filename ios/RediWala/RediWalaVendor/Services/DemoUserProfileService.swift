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
        let snapshot = try await FirebaseRTDBConnectivity.getData(
            at: root.child("users").child(uid),
            database: VendorFirebaseSession.shared.database
        )
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
        do {
            guard let profile = try await fetchUserProfile(uid: uid) else {
                #if DEBUG
                if let fallback = debugCatalogFallback(uid: uid, expected: expected) {
                    return fallback
                }
                #endif
                throw DemoAuthProfileError.missingProfile
            }
            guard profile.role == expected else {
                throw DemoAuthProfileError.wrongRole(actual: profile.role)
            }
            return profile
        } catch let error as DemoAuthProfileError {
            throw error
        } catch {
            #if DEBUG
            if FirebaseRTDBConnectivity.isOfflineError(error),
               let fallback = debugCatalogFallback(uid: uid, expected: expected) {
                return fallback
            }
            #endif
            throw error
        }
    }

    #if DEBUG
    private func debugCatalogFallback(uid: String, expected: DemoUserRole) -> DemoUserProfile? {
        guard let email = Auth.auth().currentUser?.email else { return nil }
        let account = (DemoAuthCatalog.customers + DemoAuthCatalog.vendors)
            .first { $0.email.caseInsensitiveCompare(email) == .orderedSame }
        guard let account, account.role == expected else { return nil }
        return DemoUserProfile(
            uid: uid,
            email: account.email,
            role: account.role,
            displayName: account.displayName,
            preferredLanguage: "en",
            profileCompleted: true,
            isDemoAccount: true,
            vendorId: account.vendorId
        )
    }
    #endif
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
