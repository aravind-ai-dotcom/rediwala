import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import Foundation

/// Ensures Firebase is configured, authenticated (email/password), and pointed at the correct RTDB instance.
@MainActor
final class VendorFirebaseSession: ObservableObject {
    static let shared = VendorFirebaseSession()

    enum Readiness: Equatable {
        case idle
        case loading
        case signedOut
        case ready(uid: String)
        case failed(message: String)
    }

    @Published private(set) var readiness: Readiness = .idle
    @Published private(set) var userProfile: DemoUserProfile?

    static let databaseURL = "https://rediwala-development-default-rtdb.asia-southeast1.firebasedatabase.app"

    private lazy var auth = Auth.auth()

    private init() {}

    var database: Database {
        Self.configureIfNeeded()
        return Database.database(url: Self.databaseURL)
    }

    var root: DatabaseReference {
        database.reference()
    }

    var uid: String? {
        if case .ready(let uid) = readiness { return uid }
        return auth.currentUser?.uid
    }

    var isReady: Bool {
        if case .ready = readiness { return true }
        return false
    }

    static func configureIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    /// Restore email session if present; otherwise wait at login.
    func bootstrap() async {
        readiness = .loading
        Self.configureIfNeeded()

        guard let user = auth.currentUser, user.isAnonymous == false else {
            if auth.currentUser?.isAnonymous == true {
                try? auth.signOut()
            }
            readiness = .signedOut
            userProfile = nil
            return
        }

        do {
            let profile = try await DemoUserProfileService.shared.requireRole(.vendor, for: user.uid)
            applyVendorIdentity(from: profile)
            userProfile = profile
            readiness = .ready(uid: user.uid)
        } catch {
            try? auth.signOut()
            userProfile = nil
            readiness = .signedOut
        }
    }

    func signIn(email: String, password: String) async -> Bool {
        readiness = .loading
        Self.configureIfNeeded()

        if auth.currentUser?.isAnonymous == true {
            try? auth.signOut()
        }

        do {
            let result = try await auth.signIn(
                withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            let profile = try await DemoUserProfileService.shared.requireRole(.vendor, for: result.user.uid)
            applyVendorIdentity(from: profile)
            userProfile = profile
            readiness = .ready(uid: result.user.uid)
            return true
        } catch let error as DemoAuthProfileError {
            try? auth.signOut()
            userProfile = nil
            readiness = .failed(message: error.localizedDescription)
            return false
        } catch {
            userProfile = nil
            readiness = .failed(message: AuthFriendlyError.message(for: error))
            return false
        }
    }

    func signOut() {
        try? auth.signOut()
        userProfile = nil
        VendorLiveSessionStore.clear()
        VendorIdentityStore.clear()
        readiness = .signedOut
    }

    func ensureReadyForWrites() async throws {
        if case .ready = readiness { return }
        if let user = auth.currentUser, user.isAnonymous == false {
            readiness = .ready(uid: user.uid)
            return
        }
        throw VendorFirebaseError.notAuthenticated(String(localized: "auth.error.not_signed_in"))
    }

    private func applyVendorIdentity(from profile: DemoUserProfile) {
        if let vendorId = profile.vendorId, !vendorId.isEmpty {
            VendorIdentityStore.vendorID = vendorId
        } else if let match = DemoAuthCatalog.vendors.first(where: { $0.email == profile.email })?.vendorId {
            VendorIdentityStore.vendorID = match
        }
    }
}

enum VendorFirebaseError: LocalizedError {
    case notAuthenticated(String)
    case permissionDenied
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated(let message):
            return message
        case .permissionDenied:
            return String(localized: "auth.error.permission")
        case .writeFailed(let message):
            return message
        }
    }
}
