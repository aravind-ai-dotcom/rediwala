import Combine
import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class VendorProfileViewModel: ObservableObject {
    @Published var profile: VendorProfile
    @Published var isShowingSettings = false
    @Published var isUploadingPhoto = false
    @Published var photoUploadProgress: Double = 0
    @Published var photoErrorMessage: String?

    let vendorID: String

    init(onboarding: VendorOnboardingState? = nil, languageKey: String? = nil, vendorID: String? = nil) {
        let resolvedLanguageKey = languageKey ?? AppLanguage.english.profileLabelKey
        self.vendorID = vendorID ?? onboarding?.vendorName ?? "vendor_001"
        let savedPath = VendorProfilePhotoStore.loadPath(for: self.vendorID)
        if let onboarding {
            let hoursFormatter = DateFormatter()
            hoursFormatter.timeStyle = .short
            profile = VendorProfile(
                name: onboarding.vendorName,
                languageKey: resolvedLanguageKey,
                phone: VendorMockData.defaultPhone,
                categoryKey: onboarding.category.titleKey,
                workingHours: onboarding.workingHours.formatted(using: hoursFormatter),
                areaKey: onboarding.area.labelKey,
                photoLocalPath: savedPath
            )
        } else {
            let hoursFormatter = DateFormatter()
            hoursFormatter.timeStyle = .short
            profile = VendorProfile(
                name: String(localized: String.LocalizationValue(VendorMockData.defaultVendorName)),
                languageKey: resolvedLanguageKey,
                phone: VendorMockData.defaultPhone,
                categoryKey: VendorCategory.vegetables.titleKey,
                workingHours: VendorWorkingHours.defaultHours.formatted(using: hoursFormatter),
                areaKey: ChennaiArea.tNagar.labelKey,
                photoLocalPath: savedPath
            )
        }
        Task { await retryPendingPhotoUploadIfNeeded() }
    }

    func updateLanguageKey(_ key: String) {
        profile.languageKey = key
    }

    func applySelectedPhotoItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        photoErrorMessage = nil
        isUploadingPhoto = true
        photoUploadProgress = 0.1
        defer {
            isUploadingPhoto = false
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoErrorMessage = "Unsupported image data. Please choose another photo."
                return
            }
            photoUploadProgress = 0.35
            guard let resized = image.scaledForVendorProfile(maxDimension: 1024) else {
                photoErrorMessage = "Could not process image."
                return
            }
            photoUploadProgress = 0.6
            guard let path = VendorProfilePhotoStore.save(resized, for: vendorID) else {
                photoErrorMessage = "Failed to save image locally."
                return
            }
            photoUploadProgress = 1
            profile.photoLocalPath = path
            if let data = resized.jpegData(compressionQuality: 0.78) {
                do {
                    _ = try await VendorFirebaseService.shared.uploadProfilePhoto(data, vendorID: vendorID)
                    VendorProfilePhotoStore.markPending(false, for: vendorID)
                    photoErrorMessage = nil
                } catch {
                    photoErrorMessage = "Photo saved on this device. Waiting for connection…"
                }
            }
        } catch {
            photoErrorMessage = "Photo selection failed. Please retry."
        }
    }

    func retryPendingPhotoUploadIfNeeded() async {
        guard VendorProfilePhotoStore.hasPendingUpload(for: vendorID),
              let data = VendorProfilePhotoStore.jpegData(for: vendorID) else { return }
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        do {
            _ = try await VendorFirebaseService.shared.uploadProfilePhoto(data, vendorID: vendorID)
            VendorProfilePhotoStore.markPending(false, for: vendorID)
            photoErrorMessage = nil
        } catch {
            photoErrorMessage = "Photo saved on this device. Waiting for connection…"
        }
    }

    func removePhoto() {
        VendorProfilePhotoStore.remove(for: vendorID)
        profile.photoLocalPath = nil
    }
}

private extension UIImage {
    func scaledForVendorProfile(maxDimension: CGFloat) -> UIImage? {
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
