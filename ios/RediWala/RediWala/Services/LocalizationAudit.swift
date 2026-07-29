import Foundation
import OSLog

/// Development helper: logs unresolved localization keys once.
enum LocalizationAudit {
    private static let log = Logger(subsystem: "com.rediwala.customer", category: "Localization")
    private static var reported = Set<String>()

    static func noteMissingKey(_ key: String, file: StaticString = #fileID, line: UInt = #line) {
        #if DEBUG
        guard !reported.contains(key) else { return }
        reported.insert(key)
        log.warning("Missing localization for '\(key, privacy: .public)' at \(String(describing: file), privacy: .public):\(line, privacy: .public)")
        #endif
    }

    /// Returns localized string; if it equals the key, logs once in DEBUG.
    static func localized(_ key: String) -> String {
        let value = String(localized: String.LocalizationValue(key))
        if value == key || value == key.replacingOccurrences(of: "_", with: " ") {
            noteMissingKey(key)
        }
        return value
    }
}
