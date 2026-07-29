import Foundation

enum CustomerIdentityStore {
    private static let uidKey = "customer.firebase.uid"

    static func loadUID() -> String? {
        KeychainStore.string(forKey: uidKey, service: "com.rediwala.customer")
    }

    static func save(uid: String) {
        KeychainStore.set(uid, forKey: uidKey, service: "com.rediwala.customer")
    }
}
