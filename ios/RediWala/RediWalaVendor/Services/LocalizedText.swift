import Foundation

/// Never show raw localization keys to users. Falls back to English.
nonisolated enum LocalizedText {
    nonisolated static func resolve(_ key: String, fallback: String) -> String {
        let value = String(localized: String.LocalizationValue(key))
        if value.isEmpty || value == key {
            return fallback
        }
        return value
    }
}
