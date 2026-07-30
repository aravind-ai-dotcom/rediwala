import FirebaseCore
import SwiftUI

@main
struct RediWalaCustomerApp: App {
    @UIApplicationDelegateAdaptor(CustomerAppDelegate.self) private var appDelegate
    @StateObject private var languageStore = AppLanguageStore()
    @StateObject private var authService: FirebaseAuthService
    @StateObject private var repository: FirebaseSellerRepository
    @StateObject private var favoritesViewModel: FavoritesViewModel

    init() {
        // Must run before FirebaseAuthService / Auth.auth() — @StateObject setup can
        // precede AppDelegate.didFinishLaunchingWithOptions.
        FirebaseDatabaseConfig.configureIfNeeded()

        _authService = StateObject(wrappedValue: FirebaseAuthService())
        let repository = FirebaseSellerRepository()
        _repository = StateObject(wrappedValue: repository)
        _favoritesViewModel = StateObject(wrappedValue: FavoritesViewModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            CustomerContentView(
                repository: repository,
                authService: authService
            )
            .environmentObject(languageStore)
            .environmentObject(favoritesViewModel)
            .environmentObject(authService)
            .environmentObject(GeoContext.shared)
            .environment(\.locale, languageStore.locale)
            .onAppear {
                DeviceGeoSource.shared.startIfNeeded(for: GeoContext.shared.mode)
            }
        }
    }
}
