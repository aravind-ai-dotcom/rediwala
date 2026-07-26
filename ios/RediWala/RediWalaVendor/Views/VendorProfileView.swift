import SwiftUI

struct VendorProfileView: View {
    @StateObject private var viewModel = VendorProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(AppTheme.primary)
                        .accessibilityHidden(true)

                    Text(viewModel.profile.name)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    ProfileRow(title: "Language", value: viewModel.profile.language, systemImage: "globe")
                    ProfileRow(title: "Phone", value: viewModel.profile.phone, systemImage: "phone.fill")
                    ProfileRow(
                        title: "Business Category",
                        value: viewModel.profile.category,
                        systemImage: "leaf.fill"
                    )
                    ProfileRow(
                        title: "Working Hours",
                        value: viewModel.profile.workingHours,
                        systemImage: "clock.fill"
                    )
                }

                PrimaryButton(
                    title: "Logout",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    style: .danger
                ) {
                    viewModel.logoutTapped()
                }
                .padding(.top, 8)
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    VendorProfileView()
}
