import SwiftUI
import PhotosUI
import UIKit

struct VendorProfileView: View {
    @ObservedObject var viewModel: VendorProfileViewModel
    @EnvironmentObject private var firebaseSession: VendorFirebaseSession
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                VStack(spacing: 12) {
                    let photoPath = viewModel.profile.photoLocalPath
                    let photoButtonTitle = photoPath == nil ? "Add photo" : "Edit photo"
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        ZStack(alignment: .bottom) {
                            profilePhotoView(path: photoPath)
                            Text(photoButtonTitle)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.primary.opacity(0.92))
                                .clipShape(Capsule())
                                .offset(y: 8)
                        }
                        .frame(height: 110)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(LocalizedText.resolve("profile.add_photo", fallback: "Profile photo")))

                    if photoPath != nil {
                        Button("Remove photo", role: .destructive) {
                            viewModel.removePhoto()
                        }
                        .font(.caption.weight(.semibold))
                    }

                    Text(viewModel.profile.name)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    ProfileRow(
                        titleKey: "profile.language",
                        value: LocalizedText.resolve(viewModel.profile.languageKey, fallback: "English"),
                        systemImage: "globe"
                    )
                    ProfileRow(titleKey: "profile.phone", value: viewModel.profile.phone, systemImage: "phone.fill")
                    ProfileRow(
                        titleKey: "profile.category",
                        value: LocalizedText.resolve(viewModel.profile.categoryKey, fallback: "Business"),
                        systemImage: "leaf.fill"
                    )
                    ProfileRow(
                        titleKey: "profile.working_hours",
                        value: viewModel.profile.workingHours,
                        systemImage: "clock.fill"
                    )
                    ProfileRow(
                        titleKey: "profile.area",
                        value: ChennaiArea.allCases.first { $0.labelKey == viewModel.profile.areaKey }?.localizedName
                            ?? LocalizedText.resolve(viewModel.profile.areaKey, fallback: "Neighborhood"),
                        systemImage: "mappin.and.ellipse"
                    )
                }

                if viewModel.isUploadingPhoto {
                    ProgressView(value: viewModel.photoUploadProgress) {
                        Text("Uploading…")
                            .font(.caption.weight(.semibold))
                    }
                }
                if let error = viewModel.photoErrorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                LargeActionButton(
                    titleKey: "settings.title",
                    subtitleKey: "settings.subtitle",
                    systemImage: "gearshape.fill",
                    tint: AppTheme.info
                ) {
                    viewModel.isShowingSettings = true
                }

                Button {
                    firebaseSession.signOut()
                } label: {
                    Text(LocalizedText.resolve("auth.sign_out", fallback: "Sign Out"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .sheet(isPresented: $viewModel.isShowingSettings) {
            VendorSettingsView()
        }
        .task(id: selectedPhotoItem) {
            guard selectedPhotoItem != nil else { return }
            await viewModel.applySelectedPhotoItem(selectedPhotoItem)
            selectedPhotoItem = nil
        }
    }

    @ViewBuilder
    private func profilePhotoView(path: String?) -> some View {
        if let path,
           let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(AppTheme.primary.opacity(0.12))
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.primary)
                }
        }
    }
}

#Preview {
    VendorProfileView(viewModel: VendorProfileViewModel())
        .environment(\.locale, Locale(identifier: "en"))
}
