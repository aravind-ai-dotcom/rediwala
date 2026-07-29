import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var favorites: FavoritesViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var languageStore: AppLanguageStore

    private var displayName: String {
        viewModel.persistentProfile?.displayName
            ?? String(localized: String.LocalizationValue(viewModel.profile.nameKey))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        SellerAvatarView(
                            name: displayName,
                            initials: "RW",
                            remoteURL: viewModel.profile.photoURL,
                            size: 96
                        )

                        Text("profile.add_photo")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.92))
                            .clipShape(Capsule())
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
                }
                .padding(.top, 8)

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
                        value: String(localized: String.LocalizationValue(viewModel.profile.areaKey)),
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
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("tab.profile"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load(customerID: favorites.repository.customerIDForProfile)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(FavoritesViewModel(repository: FirebaseSellerRepository()))
    .environmentObject(AppLanguageStore())
    .environment(\.locale, Locale(identifier: "en"))
}
