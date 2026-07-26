import Combine
import Foundation

@MainActor
final class VendorEarningsViewModel: ObservableObject {
    @Published var entries: [VendorEarningsEntry]
    @Published var summary: VendorDaySummary

    init(
        entries: [VendorEarningsEntry]? = nil,
        summary: VendorDaySummary? = nil
    ) {
        self.entries = entries ?? VendorMockData.earningsEntries
        self.summary = summary ?? VendorMockData.todaySummary
    }

    var totalRupees: Int {
        entries.reduce(0) { $0 + $1.amountRupees }
    }
}
