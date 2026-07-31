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
    @Published var photoUploadProgress: Double = 0
    @Published var photoErrorMessage: String?
    @Published var photoSyncLabel: String?

    private let customerRepository = FirebaseCustomerRepository()
    private var customerID: String?

    func load(customerID: String?) async {
        self.customerID = customerID
        if let customerID {
            photoLocalPath = CustomerProfilePhotoStore.loadPath(for: customerID)
            if CustomerProfilePhotoStore.hasPendingUpload(for: customerID) {
                photoSyncLabel = "Waiting for connection…"
                Task { await retryPendingPhotoUploadIfNeeded() }
            }
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
        photoSyncLabel = "Uploading…"
        isSavingPhoto = true
        photoUploadProgress = 0.15
        defer { isSavingPhoto = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoErrorMessage = "Unsupported image. Please choose another photo."
                photoSyncLabel = nil
                return
            }
            photoUploadProgress = 0.4
            guard let resized = image.scaledForProfile(maxDimension: 1024),
                  let path = CustomerProfilePhotoStore.save(resized, for: customerID),
                  let jpeg = resized.jpegData(compressionQuality: 0.82) else {
                photoErrorMessage = "Could not save photo."
                photoSyncLabel = nil
                return
            }
            photoLocalPath = path
            photoUploadProgress = 0.7
            do {
                let remoteURL = try await FirebaseStorageService.uploadCustomerProfilePhoto(
                    data: jpeg,
                    customerID: customerID
                )
                CustomerProfilePhotoStore.markPendingUpload(false, for: customerID)
                profile.photoURL = remoteURL
                var persistent = persistentProfile
                if persistent == nil {
                    persistent = await customerRepository.fetchCustomer(id: customerID)
                }
                if var profileToSave = persistent {
                    profileToSave.photoURL = remoteURL
                    persistentProfile = profileToSave
                    await customerRepository.saveCustomer(profileToSave)
                }
                photoUploadProgress = 1
                photoSyncLabel = "Uploaded"
            } catch {
                photoSyncLabel = "Waiting for connection…"
                photoErrorMessage = "Photo saved on this device. Will upload when online."
            }
        } catch {
            photoErrorMessage = "Photo selection failed. Please retry."
            photoSyncLabel = nil
        }
    }

    func removePhoto() {
        guard let customerID else { return }
        CustomerProfilePhotoStore.remove(for: customerID)
        photoLocalPath = nil
        profile.photoURL = nil
        photoSyncLabel = nil
        Task {
            var persistent = persistentProfile
            if persistent == nil {
                persistent = await customerRepository.fetchCustomer(id: customerID)
            }
            if var profileToSave = persistent {
                profileToSave.photoURL = nil
                persistentProfile = profileToSave
                await customerRepository.saveCustomer(profileToSave)
            }
        }
    }

    func retryPendingPhotoUploadIfNeeded() async {
        guard let customerID,
              CustomerProfilePhotoStore.hasPendingUpload(for: customerID),
              let jpeg = CustomerProfilePhotoStore.jpegData(for: customerID) else { return }
        photoSyncLabel = "Uploading…"
        do {
            let remoteURL = try await FirebaseStorageService.uploadCustomerProfilePhoto(
                data: jpeg,
                customerID: customerID
            )
            CustomerProfilePhotoStore.markPendingUpload(false, for: customerID)
            profile.photoURL = remoteURL
            var persistent = persistentProfile
            if persistent == nil {
                persistent = await customerRepository.fetchCustomer(id: customerID)
            }
            if var profileToSave = persistent {
                profileToSave.photoURL = remoteURL
                persistentProfile = profileToSave
                await customerRepository.saveCustomer(profileToSave)
            }
            photoSyncLabel = "Uploaded"
            photoErrorMessage = nil
        } catch {
            photoSyncLabel = "Waiting for connection…"
        }
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
