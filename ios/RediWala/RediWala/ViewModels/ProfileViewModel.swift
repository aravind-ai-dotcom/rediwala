import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: CustomerProfile = CustomerMockData.profile
    @Published private(set) var persistentProfile: PersistentCustomerProfile?
    @Published private(set) var syncMessage: String?

    private let customerRepository = FirebaseCustomerRepository()

    func load(customerID: String?) async {
        guard let customerID else { return }
        if let loaded = await customerRepository.fetchCustomer(id: customerID) {
            persistentProfile = loaded
            profile = CustomerProfile(
                nameKey: loaded.displayName,
                phone: loaded.phone ?? CustomerMockData.profile.phone,
                areaKey: loaded.areaKey,
                photoURL: loaded.photoURL
            )
        } else {
            syncMessage = "Using offline profile until connection returns."
        }
    }
}
