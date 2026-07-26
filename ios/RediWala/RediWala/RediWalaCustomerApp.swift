import SwiftUI
import FirebaseCore

@main
struct RediWalaCustomerApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            CustomerContentView()
        }
    }
}
