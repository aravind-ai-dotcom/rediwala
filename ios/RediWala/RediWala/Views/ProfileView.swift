import PhotosUI
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var favorites: FavoritesViewModel
    @EnvironmentObject private var authService: FirebaseAuthService
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var languageStore: AppLanguageStore
    @ObservedObject private var geo = GeoContext.shared
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var displayName: String {
        viewModel.persistentProfile?.displayName
            ?? authService.userProfile?.displayName
            ?? String(localized: String.LocalizationValue(viewModel.profile.nameKey))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        SellerAvatarView(
                            name: displayName,
                            initials: String(displayName.prefix(2)).uppercased(),
                            remoteURL: viewModel.profile.photoURL,
                            localPath: viewModel.photoLocalPath,
                            size: 96
                        )

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Text("profile.add_photo")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.primary.opacity(0.92))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .offset(y: 40)
                    }
                    .frame(height: 110)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("profile.add_photo"))
                    .accessibilityHint(Text("profile.add_photo.hint"))

                    Text(displayName)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.isSavingPhoto {
                        ProgressView()
                    }
                    if let error = viewModel.photoErrorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.danger)
                    }

                    HStack(spacing: 10) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(
                                viewModel.photoLocalPath == nil ? "Add Photo" : "Replace Photo",
                                systemImage: "photo.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.primary)

                        Button("Remove", role: .destructive) {
                            viewModel.removePhoto()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.photoLocalPath == nil)
                    }
                }
                .padding(.top, 8)

                geoContextCard

                VStack(spacing: 12) {
                    ProfileRow(
                        titleKey: "profile.row.language",
                        value: String(localized: String.LocalizationValue(languageStore.language.localizationKey)),
                        systemImage: "globe"
                    )
                    ProfileRow(
                        titleKey: "profile.row.phone",
                        value: viewModel.profile.phone,
                        systemImage: "phone.fill"
                    )
                    ProfileRow(
                        titleKey: "profile.row.area",
                        value: geo.neighborhood.displayName,
                        systemImage: "mappin.and.ellipse"
                    )
                }

                NavigationLink {
                    SettingsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3.weight(.bold))
                        Text("profile.settings")
                            .font(.title3.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(16)
                    .frame(minHeight: AppTheme.minTap)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    authService.signOut()
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

                #if DEBUG
                NavigationLink {
                    DemoControlView()
                } label: {
                    Text("Demo Control")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.info)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                }
                .buttonStyle(.plain)
                #endif
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("tab.profile"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            let uid = authService.currentUID ?? favorites.repository.customerIDForProfile
            await viewModel.load(customerID: uid)
        }
        .task(id: selectedPhotoItem) {
            guard selectedPhotoItem != nil else { return }
            await viewModel.applySelectedPhotoItem(selectedPhotoItem)
            selectedPhotoItem = nil
        }
    }

    private var geoContextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Neighborhood Context")
                .font(.headline.weight(.bold))
            Text("\(geo.city.displayName) · \(geo.neighborhood.displayName)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Picker("Mode", selection: Binding(
                get: { geo.mode },
                set: { geo.setMode($0); DeviceGeoSource.shared.startIfNeeded(for: $0) }
            )) {
                ForEach(GeoLocationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            Text(geo.mode.subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(FavoritesViewModel(repository: FirebaseSellerRepository()))
    .environmentObject(AppLanguageStore())
    .environmentObject(FirebaseAuthService())
    .environment(\.locale, Locale(identifier: "en"))
}
