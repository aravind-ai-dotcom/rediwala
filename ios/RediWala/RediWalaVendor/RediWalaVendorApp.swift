import SwiftUI
import UIKit

/// Keep UIApplicationDelegate visible to UIKit / Firebase swizzling.
/// Default MainActor isolation hides protocol conformance from the ObjC runtime —
/// mark the delegate entry point nonisolated and configure Firebase immediately.
@objc(VendorAppDelegate)
final class VendorAppDelegate: NSObject, UIApplicationDelegate {
    nonisolated func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        VendorFirebaseBootstrap.configureIfNeeded()
        return true
    }
}

@main
struct RediWalaVendorApp: App {
    @UIApplicationDelegateAdaptor(VendorAppDelegate.self) private var appDelegate

    @StateObject private var languageStore: AppLanguageStore

    init() {
        // First line — before ContentView / session singletons touch Auth or RTDB.
        VendorFirebaseBootstrap.configureIfNeeded()
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
