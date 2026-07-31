import FirebaseCore
import UIKit

@objc(CustomerAppDelegate)
final class CustomerAppDelegate: NSObject, UIApplicationDelegate {
    nonisolated func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseDatabaseConfig.configureIfNeeded()
        return true
    }
}
