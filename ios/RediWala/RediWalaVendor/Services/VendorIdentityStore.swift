import Foundation
import Security

enum VendorIdentityStore {
    private static let vendorIDKey = "vendor.firebase.id"
    private static let service = "com.rediwala.vendor"

    /// Demo pilot vendor ID aligned with Firebase seed / synthetic Murugan.
    static let demoVendorID = "murugan"

    static var vendorID: String {
        get { load(key: vendorIDKey) ?? demoVendorID }
        set { save(newValue, key: vendorIDKey) }
    }

    static func resolveVendorID(displayName: String) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.contains("murugan") { return "murugan" }
        if trimmed.contains("lakshmi") && trimmed.contains("flower") { return "lakshmi" }
        if trimmed.contains("siva") || trimmed.contains("iron") { return "siva_ironing" }
        if trimmed.contains("babu") || trimmed.contains("laundry") { return "babu_laundry" }
        if trimmed.contains("kumar") || trimmed.contains("cable") { return "kumar_cable" }
        return demoVendorID
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: vendorIDKey,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private static func save(_ value: String, key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        _ = SecItemAdd(attributes as CFDictionary, nil)
    }
}
