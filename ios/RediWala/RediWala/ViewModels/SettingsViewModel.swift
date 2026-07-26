import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    func selectLanguage(_ language: AppLanguage, store: AppLanguageStore) {
        store.select(language)
    }
}
