import Combine
import Foundation
import SwiftUI

@MainActor
final class AppLanguageStore: ObservableObject {
    @Published var language: AppLanguage = .english {
        didSet { persistLanguage() }
    }

    private let storageKey = "customer.app.language"

    init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let restored = AppLanguage(rawValue: saved) {
            language = restored
        }
    }

    var locale: Locale {
        language.locale
    }

    func select(_ language: AppLanguage) {
        self.language = language
    }

    private func persistLanguage() {
        UserDefaults.standard.set(language.rawValue, forKey: storageKey)
        CustomerPreferenceSyncService.scheduleSync()
    }
}
