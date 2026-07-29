import Foundation

/// Demo billing record. Future-ready for GST, invoice numbers, inventory lines.
struct VendorBillDraft: Equatable {
    var amountRupees: Int = 0
    var notes: String = ""
}

struct VendorPaymentRecord: Identifiable, Codable, Equatable {
    let id: String
    var vendorID: String
    var vendorName: String
    var businessName: String
    var amountRupees: Int
    var notes: String?
    var createdAt: Date
    var isCompleted: Bool

    // Future fields
    var invoiceNumber: String?
    var gstAmountRupees: Int?
    var lineItems: [VendorBillLineItem]?
}

struct VendorBillLineItem: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var quantity: Double
    var unitPriceRupees: Int
}

@MainActor
enum VendorBillingStore {
    private static let key = VendorCacheKeys.billingTransactions

    static func load(vendorID: String) -> [VendorPaymentRecord] {
        let all = VendorLocalJSONCache.load([VendorPaymentRecord].self, key: key) ?? []
        return all.filter { $0.vendorID == vendorID }.sorted { $0.createdAt > $1.createdAt }
    }

    static func save(_ record: VendorPaymentRecord) {
        var all = VendorLocalJSONCache.load([VendorPaymentRecord].self, key: key) ?? []
        all.removeAll { $0.id == record.id }
        all.insert(record, at: 0)
        VendorLocalJSONCache.save(all, key: key)
    }

    static func todayTotal(vendorID: String) -> Int {
        let calendar = Calendar.current
        return load(vendorID: vendorID)
            .filter { calendar.isDateInToday($0.createdAt) && $0.isCompleted }
            .map(\.amountRupees)
            .reduce(0, +)
    }

    static func todayCustomerCount(vendorID: String) -> Int {
        let calendar = Calendar.current
        return load(vendorID: vendorID).filter { calendar.isDateInToday($0.createdAt) && $0.isCompleted }.count
    }
}
