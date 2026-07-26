import Combine
import Foundation

@MainActor
final class VendorLiveViewModel: ObservableObject {
    @Published var area: ChennaiArea
    @Published var startTimeLabel: String = "—"
    @Published var customersToday: Int = 0

    init(area: ChennaiArea? = nil) {
        self.area = area ?? VendorMockData.defaultArea
    }

    var locationLabel: String {
        VendorMockData.locationLabel(for: area)
    }

    func beginSession(now: Date = Date()) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        startTimeLabel = formatter.string(from: now)
        customersToday = 3
    }
}
