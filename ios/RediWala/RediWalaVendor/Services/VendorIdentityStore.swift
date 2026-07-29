import Foundation
import Security

enum VendorIdentityStore {
    private static let vendorIDKey = "vendor.firebase.id"
    private static let service = "com.rediwala.vendor"

    /// Demo pilot vendor ID aligned with Firebase seed data (`vendor_001` = Murugan).
    static let demoVendorID = "vendor_001"

    static var vendorID: String {
        get { load(key: vendorIDKey) ?? demoVendorID }
        set { save(newValue, key: vendorIDKey) }
    }

    static func resolveVendorID(displayName: String) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed == "murugan" || trimmed.isEmpty {
            return demoVendorID
        }
        return demoVendorID
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
