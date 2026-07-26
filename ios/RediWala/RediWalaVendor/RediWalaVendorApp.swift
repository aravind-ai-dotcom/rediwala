import SwiftUI
import FirebaseCore

@main
struct RediWalaVendorApp: App {

    @StateObject private var languageStore = AppLanguageStore()

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageStore)
                .environment(\.locale, languageStore.locale)
        }
    }
}
