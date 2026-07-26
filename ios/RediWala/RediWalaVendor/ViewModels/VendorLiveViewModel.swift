import Combine
import Foundation

@MainActor
final class VendorLiveViewModel: ObservableObject {
    @Published var locationLabel: String = "Near Market Road"
    @Published var startTimeLabel: String = "—"
    @Published var customersToday: Int = 0

    func beginSession(now: Date = Date()) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        startTimeLabel = formatter.string(from: now)
        customersToday = 0
    }
}
