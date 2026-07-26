import FirebaseCore
import SwiftUI

@main
struct RediWalaCustomerApp: App {
    @StateObject private var languageStore = AppLanguageStore()
    @StateObject private var favoritesViewModel: FavoritesViewModel

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        let repository = LocalSellerRepository()
        _favoritesViewModel = StateObject(wrappedValue: FavoritesViewModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            CustomerContentView(repository: favoritesViewModel.repository)
                .environmentObject(languageStore)
                .environmentObject(favoritesViewModel)
                .environment(\.locale, languageStore.locale)
        }
    }
}
