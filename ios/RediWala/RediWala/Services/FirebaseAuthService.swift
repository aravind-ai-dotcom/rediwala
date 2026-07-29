import Combine
import FirebaseAuth
import Foundation

/// Owns Firebase Authentication for the Customer app.
@MainActor
final class FirebaseAuthService: ObservableObject {
    enum State: Equatable {
        case loading
        case signedIn(uid: String)
        case failed(message: String)
    }

    @Published private(set) var state: State = .loading

    private lazy var auth = Auth.auth()

    func signInAnonymouslyIfNeeded() async -> String? {
        state = .loading

        if let existingUser = auth.currentUser {
            state = .signedIn(uid: existingUser.uid)
            CustomerIdentityStore.save(uid: existingUser.uid)
            return existingUser.uid
        }

        if let cached = CustomerIdentityStore.loadUID() {
            // Firebase Auth persists sessions internally; if currentUser is nil the cache is stale.
            _ = cached
        }

        do {
            let result = try await auth.signInAnonymously()
            let uid = result.user.uid
            CustomerIdentityStore.save(uid: uid)
            state = .signedIn(uid: uid)
            return uid
        } catch {
            state = .failed(message: error.localizedDescription)
            return nil
        }
    }

    var currentUID: String? {
        auth.currentUser?.uid
    }
}
