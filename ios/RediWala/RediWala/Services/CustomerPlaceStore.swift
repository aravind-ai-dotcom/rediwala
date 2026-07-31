import Combine
import Foundation

/// Important places a customer can target recommendations against.
enum CustomerPlaceKind: String, CaseIterable, Identifiable, Codable {
    case home
    case parents
    case office
    case friend
    case school
    case current

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .parents: return "Parents"
        case .office: return "Office"
        case .friend: return "Friend"
        case .school: return "School"
        case .current: return "Current location"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .parents: return "figure.2.and.child.holdinghands"
        case .office: return "building.2.fill"
        case .friend: return "person.2.fill"
        case .school: return "graduationcap.fill"
        case .current: return "location.fill"
        }
    }
}

@MainActor
final class CustomerPlaceStore: ObservableObject {
    static let shared = CustomerPlaceStore()

    private let activeKey = "customer.active_place.v1"

    @Published var activePlace: CustomerPlaceKind {
        didSet {
            UserDefaults.standard.set(activePlace.rawValue, forKey: activeKey)
            CustomerPreferenceSyncService.scheduleSync()
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: activeKey),
           let place = CustomerPlaceKind(rawValue: raw) {
            activePlace = place
        } else {
            activePlace = .home
        }
    }

    /// Human distance / ETA language relative to the active place.
    func proximityPhrase(meters: Int, etaLabel: String?, isLive: Bool) -> String {
        let place = activePlace.title.lowercased()
        if let etaLabel, !etaLabel.isEmpty {
            if etaLabel.localizedCaseInsensitiveContains("corner") {
                return "Near your \(place)"
            }
            if etaLabel.localizedCaseInsensitiveContains("min") {
                return "\(etaLabel) from \(place)"
            }
            if etaLabel.localizedCaseInsensitiveContains("tomorrow") {
                return etaLabel
            }
        }
        if isLive {
            if meters < 180 { return "Passing your street" }
            if meters < 600 { return "Approaching your neighborhood" }
            return "\(max(3, min(45, meters / 40))) min from \(place)"
        }
        if meters < 250 { return "Near your \(place)" }
        if meters < 900 { return "Expected near \(place)" }
        return "\(max(5, min(50, meters / 40))) min from \(place)"
    }
}
