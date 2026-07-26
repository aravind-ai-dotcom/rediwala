import Combine
import Foundation
import SwiftUI

@MainActor
final class AppLanguageStore: ObservableObject {
    @Published var selected: AppLanguage {
        didSet {
            UserDefaults.standard.set(selected.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "vendor.app.language"

    var locale: Locale {
        Locale(identifier: selected.localeIdentifier)
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let language = AppLanguage(rawValue: raw) {
            selected = language
        } else {
            selected = .english
        }
    }

    func select(_ language: AppLanguage) {
        selected = language
    }
}
