import Combine
import FirebaseAuth
import Foundation

/// Owns Firebase Authentication for the Vendor app.
/// UI observes `state`; all Auth SDK work stays here.
@MainActor
final class FirebaseAuthService: ObservableObject {

    enum State: Equatable {
        case loading
        case signedIn(uid: String)
        case failed(message: String)
    }

    @Published private(set) var state: State = .loading

    /// Lazily resolved after `FirebaseApp.configure()` so Auth is never touched too early.
    private lazy var auth = Auth.auth()

    /// Signs in anonymously, or reuses an existing Firebase user session.
    func signInAnonymouslyIfNeeded() async {
        state = .loading

        if let existingUser = auth.currentUser {
            state = .signedIn(uid: existingUser.uid)
            return
        }

        do {
            let result = try await auth.signInAnonymously()
            state = .signedIn(uid: result.user.uid)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
