import Combine
import Foundation

@MainActor
final class VendorProfileViewModel: ObservableObject {
    @Published var profile = VendorProfile(
        name: "Kumar",
        language: "Hindi",
        phone: "+91 98765 43210",
        category: "Vegetables",
        workingHours: "6:00 AM – 8:00 PM"
    )

    @Published var didRequestLogout = false

    func logoutTapped() {
        didRequestLogout = true
    }
}
