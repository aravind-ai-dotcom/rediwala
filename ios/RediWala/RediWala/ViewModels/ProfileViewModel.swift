import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: CustomerProfile = CustomerMockData.profile
}
