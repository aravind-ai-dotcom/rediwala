import Combine
import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: CustomerProfile = CustomerMockData.profile
    @Published private(set) var persistentProfile: PersistentCustomerProfile?
    @Published private(set) var syncMessage: String?
    @Published var photoLocalPath: String?
    @Published var isSavingPhoto = false
    @Published var photoErrorMessage: String?

    private let customerRepository = FirebaseCustomerRepository()
    private var customerID: String?

    func load(customerID: String?) async {
        self.customerID = customerID
        if let customerID {
            photoLocalPath = CustomerProfilePhotoStore.loadPath(for: customerID)
        }
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

    func applySelectedPhotoItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let customerID else {
            photoErrorMessage = "Sign in to save a profile photo."
            return
        }
        photoErrorMessage = nil
        isSavingPhoto = true
        defer { isSavingPhoto = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoErrorMessage = "Unsupported image. Please choose another photo."
                return
            }
            guard let resized = image.scaledForProfile(maxDimension: 1024),
                  let path = CustomerProfilePhotoStore.save(resized, for: customerID) else {
                photoErrorMessage = "Could not save photo."
                return
            }
            photoLocalPath = path
        } catch {
            photoErrorMessage = "Photo selection failed. Please retry."
        }
    }

    func removePhoto() {
        guard let customerID else { return }
        CustomerProfilePhotoStore.remove(for: customerID)
        photoLocalPath = nil
    }
}

private extension UIImage {
    func scaledForProfile(maxDimension: CGFloat) -> UIImage? {
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return self }
        let ratio = maxDimension / largest
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
