import SwiftUI
import FirebaseCore
import UIKit

final class VendorAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        VendorFirebaseSession.configureIfNeeded()
        return true
    }
}

@main
struct RediWalaVendorApp: App {
    @UIApplicationDelegateAdaptor(VendorAppDelegate.self) private var appDelegate

    @StateObject private var languageStore: AppLanguageStore

    init() {
        // Configure before any Auth/Database access from ContentView / session singleton.
        VendorFirebaseSession.configureIfNeeded()
        _languageStore = StateObject(wrappedValue: AppLanguageStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageStore)
                .environment(\.locale, languageStore.locale)
        }
    }
}
