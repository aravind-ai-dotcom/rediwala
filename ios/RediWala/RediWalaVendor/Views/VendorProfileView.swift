import SwiftUI
import PhotosUI

struct VendorProfileView: View {
    @ObservedObject var viewModel: VendorProfileViewModel
    @EnvironmentObject private var firebaseSession: VendorFirebaseSession
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                VStack(spacing: 12) {
                    ZStack {
                        profilePhotoView
                        photoBadge
                    }
                    .frame(height: 100)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("profile.add_photo"))

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
                        value: String(localized: String.LocalizationValue(viewModel.profile.languageKey)),
                        systemImage: "globe"
                    )
                    ProfileRow(titleKey: "profile.phone", value: viewModel.profile.phone, systemImage: "phone.fill")
                    ProfileRow(
                        titleKey: "profile.category",
                        value: String(localized: String.LocalizationValue(viewModel.profile.categoryKey)),
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
                        Text("Uploading photo…")
                            .font(.caption.weight(.semibold))
                    }
                }
                if let error = viewModel.photoErrorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 10) {
                    let photoButtonTitle = viewModel.profile.photoLocalPath == nil ? "Select Photo" : "Replace Photo"
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Label(photoButtonTitle, systemImage: "photo.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)

                    Button("Remove", role: .destructive) {
                        viewModel.removePhoto()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.profile.photoLocalPath == nil)
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
                    Text("auth.sign_out")
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
        }
    }

    @ViewBuilder
    private var profilePhotoView: some View {
        if let path = viewModel.profile.photoLocalPath,
           let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(AppTheme.primary)
                .accessibilityHidden(true)
        }
    }

    private var photoBadge: some View {
        Text("profile.add_photo")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.primary.opacity(0.92))
            .clipShape(Capsule())
            .offset(y: 36)
    }
}

#Preview {
    VendorProfileView(viewModel: VendorProfileViewModel())
        .environment(\.locale, Locale(identifier: "en"))
}
