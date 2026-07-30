import FirebaseCore
import SwiftUI

@main
struct RediWalaCustomerApp: App {
    @UIApplicationDelegateAdaptor(CustomerAppDelegate.self) private var appDelegate
    @StateObject private var languageStore = AppLanguageStore()
    @StateObject private var authService = FirebaseAuthService()
    @StateObject private var repository: FirebaseSellerRepository
    @StateObject private var favoritesViewModel: FavoritesViewModel

    init() {
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
            .environment(\.locale, languageStore.locale)
        }
    }
}
