import SwiftUI

struct VendorProfileView: View {
    @ObservedObject var viewModel: VendorProfileViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                VStack(spacing: 12) {
                    ZStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 88))
                            .foregroundStyle(AppTheme.primary)
                            .accessibilityHidden(true)

                        Text("profile.add_photo")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.92))
                            .clipShape(Capsule())
                            .offset(y: 36)
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
                        value: String(localized: String.LocalizationValue(viewModel.profile.areaKey)),
                        systemImage: "mappin.and.ellipse"
                    )
                }

                LargeActionButton(
                    titleKey: "settings.title",
                    subtitleKey: "settings.subtitle",
                    systemImage: "gearshape.fill",
                    tint: AppTheme.info
                ) {
                    viewModel.isShowingSettings = true
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .sheet(isPresented: $viewModel.isShowingSettings) {
            VendorSettingsView()
        }
    }
}

#Preview {
    VendorProfileView(viewModel: VendorProfileViewModel())
        .environment(\.locale, Locale(identifier: "en"))
}
