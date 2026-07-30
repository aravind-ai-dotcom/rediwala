import Combine
import FirebaseAuth
import Foundation

/// Owns Firebase Authentication for the Customer app (email/password demo + session restore).
@MainActor
final class FirebaseAuthService: ObservableObject {
    enum State: Equatable {
        case loading
        case signedOut
        case signedIn(uid: String)
        case failed(message: String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var userProfile: DemoUserProfile?
    @Published private(set) var isAuthenticating = false

    private lazy var auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        FirebaseDatabaseConfig.configureIfNeeded()
        handle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }
                if let user {
                    self.state = .signedIn(uid: user.uid)
                    CustomerIdentityStore.save(uid: user.uid)
                } else if case .loading = self.state {
                    self.state = .signedOut
                } else if self.userProfile != nil || self.isAuthenticating {
                    // Keep transient states during explicit sign-in.
                } else {
                    self.state = .signedOut
                    self.userProfile = nil
                }
            }
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var currentUID: String? { auth.currentUser?.uid }
    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return auth.currentUser != nil
    }

    /// Restore an existing Firebase Auth session and verify Customer role.
    func restoreSessionIfNeeded() async {
        state = .loading
        FirebaseDatabaseConfig.configureIfNeeded()
        guard let user = auth.currentUser else {
            state = .signedOut
            userProfile = nil
            return
        }
        do {
            let profile = try await DemoUserProfileService.shared.requireRole(.customer, for: user.uid)
            userProfile = profile
            CustomerIdentityStore.save(uid: user.uid)
            state = .signedIn(uid: user.uid)
            await CustomerSessionApplier.apply(profile: profile)
        } catch {
            try? auth.signOut()
            CustomerSessionApplier.clear()
            userProfile = nil
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async -> Bool {
        isAuthenticating = true
        state = .loading
        defer { isAuthenticating = false }

        FirebaseDatabaseConfig.configureIfNeeded()

        // Replace any anonymous session before email sign-in.
        if auth.currentUser?.isAnonymous == true {
            try? auth.signOut()
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            #if DEBUG
            let result = try await DemoAuthBootstrap.signInOrCreate(
                email: trimmedEmail,
                password: password,
                expectedRole: .customer,
                auth: auth,
                database: FirebaseDatabaseConfig.root
            )
            #else
            let result = try await auth.signIn(withEmail: trimmedEmail, password: password)
            #endif
            let profile = try await DemoUserProfileService.shared.requireRole(.customer, for: result.user.uid)
            userProfile = profile
            CustomerIdentityStore.save(uid: result.user.uid)
            state = .signedIn(uid: result.user.uid)
            await CustomerSessionApplier.apply(profile: profile)
            return true
        } catch let error as DemoAuthProfileError {
            try? auth.signOut()
            CustomerSessionApplier.clear()
            userProfile = nil
            state = .failed(message: error.localizedDescription)
            return false
        } catch {
            userProfile = nil
            state = .failed(message: AuthFriendlyError.message(for: error, email: trimmedEmail))
            return false
        }
    }

    func signOut() {
        try? auth.signOut()
        userProfile = nil
        CustomerSessionApplier.clear()
        CustomerIdentityStore.clear()
        state = .signedOut
    }

    /// Legacy helper — prefer email sign-in. Kept for offline bootstrap fallback in tests.
    func signInAnonymouslyIfNeeded() async -> String? {
        if let uid = currentUID { return uid }
        do {
            let result = try await auth.signInAnonymously()
            CustomerIdentityStore.save(uid: result.user.uid)
            state = .signedIn(uid: result.user.uid)
            return result.user.uid
        } catch {
            state = .failed(message: AuthFriendlyError.message(for: error))
            return nil
        }
    }
}
