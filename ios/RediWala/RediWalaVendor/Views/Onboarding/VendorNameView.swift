import SwiftUI

struct VendorNameView: View {
    @ObservedObject var viewModel: VendorOnboardingViewModel
    var onContinue: () -> Void

    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("onboarding.name.title")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)

                    Text("onboarding.name.subtitle")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                TextField(
                    String(localized: String.LocalizationValue("onboarding.name.placeholder")),
                    text: $viewModel.vendorName
                )
                .font(.title.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .frame(minHeight: 72)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                .focused($isNameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .onSubmit {
                    if viewModel.canContinueFromName {
                        onContinue()
                    }
                }
                .accessibilityLabel(Text("onboarding.name.placeholder"))

                // Visible profile photo placeholder — no camera access this sprint.
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("onboarding.photo.title")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("onboarding.photo.subtitle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                .accessibilityElement(children: .combine)
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                titleKey: "common.continue",
                systemImage: "arrow.right",
                isEnabled: viewModel.canContinueFromName,
                prominent: true
            ) {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            isNameFocused = true
        }
    }
}

#Preview {
    VendorNameView(viewModel: VendorOnboardingViewModel(), onContinue: {})
        .environment(\.locale, Locale(identifier: "en"))
}
