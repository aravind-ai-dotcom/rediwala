import Combine
import Foundation

@MainActor
final class VendorEarningsViewModel: ObservableObject {
    @Published var entries: [VendorEarningsEntry]
    @Published var summary: VendorDaySummary
    @Published var topSellingItem: String

    private let vendorID: String

    init(vendorID: String) {
        self.vendorID = vendorID
        let sales = VendorBillingStore.load(vendorID: vendorID)
        let calendar = Calendar.current
        let today = sales.filter { calendar.isDateInToday($0.createdAt) && $0.isCompleted }
        if today.isEmpty {
            self.entries = VendorMockData.earningsEntries(for: .vegetables)
            self.summary = VendorMockData.todaySummary
            self.topSellingItem = VendorMockData.offerings(for: .vegetables).first?.displayName ?? "Today's Offerings"
        } else {
            self.entries = today.map { record in
                VendorEarningsEntry(
                    id: record.id,
                    descriptionKey: record.notes?.isEmpty == false ? (record.notes ?? "Sale") : "Sale from Today's Offerings",
                    amountRupees: record.amountRupees,
                    timeLabel: Self.time.string(from: record.createdAt),
                    offeringId: record.lineItems?.first?.id
                )
            }
            self.summary = VendorDaySummary(
                salesRupees: today.reduce(0) { $0 + $1.amountRupees },
                customers: today.count,
                hours: 0
            )
            self.topSellingItem = today
                .compactMap(\.lineItems?.first?.name)
                .first ?? "Today's Offerings"
        }
    }

    var totalRupees: Int {
        max(summary.salesRupees, entries.reduce(0) { $0 + $1.amountRupees })
    }

    var averageSale: Int {
        guard !entries.isEmpty else { return 0 }
        return totalRupees / entries.count
    }

    func refresh(liveHours: Double = 0) {
        summary.hours = liveHours
        summary.salesRupees = VendorBillingStore.todayTotal(vendorID: vendorID)
        summary.customers = VendorBillingStore.todayCustomerCount(vendorID: vendorID)
    }

    private static let time: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
