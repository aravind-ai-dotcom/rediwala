import FirebaseAuth
import FirebaseDatabase
import Foundation

/// Maps Firebase Auth failures to user-facing copy. Never exposes raw SDK codes in Release.
enum AuthFriendlyError {
    static func message(for error: Error, email: String? = nil) -> String {
        let ns = error as NSError
        let code = authErrorCode(from: ns)
        let base: String

        switch code {
        case .wrongPassword, .invalidCredential, .invalidEmail:
            if let email, isDemoEmail(email) {
                base = String(localized: "auth.error.demo_not_seeded")
            } else {
                base = String(localized: "auth.error.invalid_credentials")
            }
        case .userNotFound:
            if let email, isDemoEmail(email) {
                base = String(localized: "auth.error.demo_not_seeded")
            } else {
                base = String(localized: "auth.error.user_not_found")
            }
        case .userDisabled:
            base = String(localized: "auth.error.disabled")
        case .networkError:
            base = String(localized: "auth.error.offline")
        case .tooManyRequests:
            base = String(localized: "auth.error.too_many")
        case .operationNotAllowed:
            base = String(localized: "auth.error.operation_not_allowed")
        case .emailAlreadyInUse:
            base = String(localized: "auth.error.invalid_credentials")
        default:
            base = String(localized: "auth.error.generic")
        }

        #if DEBUG
        let detail = " [\(ns.domain) \(ns.code)] \(ns.localizedDescription)"
        print("Auth error\(detail)")
        return base + detail
        #else
        return base
        #endif
    }

    private static func authErrorCode(from ns: NSError) -> AuthErrorCode? {
        if ns.domain == AuthErrorDomain {
            return AuthErrorCode(rawValue: ns.code)
        }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == AuthErrorDomain {
            return AuthErrorCode(rawValue: underlying.code)
        }
        return AuthErrorCode(rawValue: ns.code)
    }

    private static func isDemoEmail(_ email: String) -> Bool {
        email.lowercased().hasSuffix("@demo.rediwala")
    }
}

#if DEBUG
@MainActor
enum DemoAuthBootstrap {
    static func signInOrCreate(
        email: String,
        password: String,
        expectedRole: DemoUserRole,
        auth: Auth,
        database: DatabaseReference
    ) async throws -> AuthDataResult {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let result = try await auth.signIn(withEmail: trimmed, password: password)
            try await ensureRoleProfileIfMissing(
                uid: result.user.uid,
                email: trimmed,
                expectedRole: expectedRole,
                database: database
            )
            return result
        } catch {
            guard canAttemptCreate(for: trimmed, error: error) else { throw error }
            do {
                let created = try await auth.createUser(withEmail: trimmed, password: password)
                try await ensureRoleProfile(
                    uid: created.user.uid,
                    email: trimmed,
                    expectedRole: expectedRole,
                    database: database
                )
                return created
            } catch {
                let retry = try await auth.signIn(withEmail: trimmed, password: password)
                try await ensureRoleProfileIfMissing(
                    uid: retry.user.uid,
                    email: trimmed,
                    expectedRole: expectedRole,
                    database: database
                )
                return retry
            }
        }
    }

    private static func ensureRoleProfileIfMissing(
        uid: String,
        email: String,
        expectedRole: DemoUserRole,
        database: DatabaseReference
    ) async throws {
        let snapshot = try await database.child("users").child(uid).getData()
        if snapshot.exists() { return }
        try await ensureRoleProfile(uid: uid, email: email, expectedRole: expectedRole, database: database)
    }

    static func ensureRoleProfile(
        uid: String,
        email: String,
        expectedRole: DemoUserRole,
        database: DatabaseReference
    ) async throws {
        let account = (DemoAuthCatalog.customers + DemoAuthCatalog.vendors)
            .first { $0.email.caseInsensitiveCompare(email) == .orderedSame }
        let now = ISO8601DateFormatter().string(from: Date())
        var userPayload: [String: Any] = [
            "uid": uid,
            "email": email,
            "role": expectedRole.rawValue,
            "displayName": account?.displayName ?? email,
            "preferredLanguage": "en",
            "profileCompleted": true,
            "createdAt": now,
            "updatedAt": now,
            "isDemoAccount": true,
        ]
        if expectedRole == .vendor, let vendorId = account?.vendorId {
            userPayload["vendorId"] = vendorId
        }
        try await database.child("users").child(uid).setValue(userPayload)
        if expectedRole == .vendor, let vendorId = account?.vendorId {
            try await database.child("vendors").child(vendorId).updateChildValues([
                "ownerUid": uid,
                "businessName": account?.displayName ?? vendorId,
                "displayName": account?.displayName ?? vendorId,
                "isDemoAccount": true,
                "updatedAt": now,
            ])
        }
    }

    private static func canAttemptCreate(for email: String, error: Error) -> Bool {
        guard email.lowercased().hasSuffix("@demo.rediwala") else { return false }
        let ns = error as NSError
        let code = AuthErrorCode(rawValue: ns.code)
        switch code {
        case .userNotFound, .wrongPassword, .invalidCredential, .invalidEmail:
            return true
        case .operationNotAllowed, .networkError, .tooManyRequests, .userDisabled:
            return false
        default:
            return ns.domain == AuthErrorDomain
        }
    }
}
#endif
