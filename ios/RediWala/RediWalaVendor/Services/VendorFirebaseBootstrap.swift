import FirebaseCore
import FirebaseDatabase
import Foundation

/// Nonisolated Firebase bootstrap — safe under SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor.
/// Call before any Auth / Database / Storage use.
enum VendorFirebaseBootstrap: Sendable {
    nonisolated static let databaseURL = "https://rediwala-development-default-rtdb.firebaseio.com"

    nonisolated static func configureIfNeeded() {
        if FirebaseApp.app() == nil {
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: path) {
                options.databaseURL = databaseURL
                FirebaseApp.configure(options: options)
            } else {
                FirebaseApp.configure()
            }
        }
        Database.database(url: databaseURL).goOnline()
    }
}
