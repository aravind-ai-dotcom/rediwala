import SwiftUI
import FirebaseCore

@main
struct RediWalaVendorApp: App {

    @StateObject private var authService: FirebaseAuthService

    init() {
        // Configure Firebase before any Auth-dependent objects are created.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        _authService = StateObject(wrappedValue: FirebaseAuthService())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .task {
                    await authService.signInAnonymouslyIfNeeded()
                }
        }
    }
}
