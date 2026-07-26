import Combine
import Foundation

@MainActor
final class VendorHomeViewModel: ObservableObject {
    @Published var vendorName: String
    @Published var status: VendorLiveStatus = .offline
    @Published var summary: VendorDaySummary
    @Published var area: ChennaiArea

    init(
        vendorName: String? = nil,
        summary: VendorDaySummary? = nil,
        area: ChennaiArea? = nil
    ) {
        self.vendorName = vendorName
            ?? String(localized: String.LocalizationValue(VendorMockData.defaultVendorName))
        self.summary = summary ?? VendorMockData.emptyDaySummary
        self.area = area ?? VendorMockData.defaultArea
    }

    var greetingKey: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "greeting.morning"
        case 12..<17: return "greeting.afternoon"
        default: return "greeting.evening"
        }
    }

    /// Display greeting with a light time-of-day accent for morning.
    var greetingWithAccent: String {
        let base = String(localized: String.LocalizationValue(greetingKey))
        if greetingKey == "greeting.morning" {
            return "\(base) ☀️"
        }
        return base
    }

    var statusTitleKey: String {
        switch status {
        case .offline: return "status.offline"
        case .live: return "status.live"
        }
    }

    func goLive() {
        status = .live
    }

    func stopLive() {
        status = .offline
    }

    func applyOnboarding(_ state: VendorOnboardingState) {
        vendorName = state.vendorName
        area = state.area
    }
}
