import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import Foundation

/// Ensures Firebase is configured, authenticated, and pointed at the correct RTDB instance.
@MainActor
final class VendorFirebaseSession: ObservableObject {
    static let shared = VendorFirebaseSession()

    enum Readiness: Equatable {
        case idle
        case loading
        case ready(uid: String)
        case failed(message: String)
    }

    @Published private(set) var readiness: Readiness = .idle

    /// Chennai pilot RTDB (asia-southeast1). Required because GoogleService-Info.plist has no DATABASE_URL.
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

    /// Call once at app launch before any RTDB access.
    func bootstrap() async {
        readiness = .loading
        Self.configureIfNeeded()

        if let user = auth.currentUser {
            readiness = .ready(uid: user.uid)
            return
        }

        do {
            let result = try await auth.signInAnonymously()
            readiness = .ready(uid: result.user.uid)
        } catch {
            readiness = .failed(message: error.localizedDescription)
        }
    }

    /// Throws if anonymous auth is not available. All vendor writes must call this first.
    func ensureReadyForWrites() async throws {
        if case .ready = readiness { return }
        if auth.currentUser != nil {
            readiness = .ready(uid: auth.currentUser!.uid)
            return
        }
        await bootstrap()
        if case .ready = readiness { return }
        if case .failed(let message) = readiness {
            throw VendorFirebaseError.notAuthenticated(message)
        }
        throw VendorFirebaseError.notAuthenticated("Firebase sign-in is still in progress.")
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
            return "Firebase denied this write. Confirm anonymous auth is enabled and database rules are deployed."
        case .writeFailed(let message):
            return message
        }
    }
}
