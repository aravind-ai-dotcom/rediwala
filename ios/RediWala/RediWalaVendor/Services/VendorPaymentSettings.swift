import Foundation

/// Vendor UPI / GPay details for collecting money. Not full accounting — just daily collections.
enum VendorPaymentSettings {
    private static let upiKey = "vendor.upi.id"
    private static let payeeNameKey = "vendor.upi.payee_name"

    /// Demo Murugan UPI — vendor can change in profile later.
    static var upiID: String {
        get { UserDefaults.standard.string(forKey: upiKey) ?? "muruganvegetables@okaxis" }
        set { UserDefaults.standard.set(newValue, forKey: upiKey) }
    }

    static var payeeName: String {
        get { UserDefaults.standard.string(forKey: payeeNameKey) ?? "Murugan Vegetables" }
        set { UserDefaults.standard.set(newValue, forKey: payeeNameKey) }
    }
}
