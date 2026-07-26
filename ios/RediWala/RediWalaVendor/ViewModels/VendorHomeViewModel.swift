import Combine
import Foundation

@MainActor
final class VendorHomeViewModel: ObservableObject {
    @Published var vendorName: String = "Kumar"
    @Published var status: VendorLiveStatus = .offline
    @Published var summary: VendorDaySummary = .init(salesRupees: 0, customers: 0, hours: 0)

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var statusTitle: String {
        switch status {
        case .offline: return "OFFLINE"
        case .live: return "LIVE"
        }
    }

    func goLive() {
        status = .live
    }

    func stopLive() {
        status = .offline
    }
}
