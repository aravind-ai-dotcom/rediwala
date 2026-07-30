import SwiftUI
import PhotosUI
import UIKit

struct VendorNameView: View {
    @ObservedObject var viewModel: VendorOnboardingViewModel
    var onContinue: () -> Void

    @FocusState private var isNameFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?

    private var draftVendorID: String {
        let name = viewModel.trimmedName.lowercased().replacingOccurrences(of: " ", with: "_")
        return name.isEmpty ? "onboarding_draft" : name
    }

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

                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 14) {
                        if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 44))
                                .foregroundStyle(AppTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("onboarding.photo.title")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Add Photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                            Text("onboarding.photo.subtitle")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                }
                .buttonStyle(.plain)
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
            if let path = VendorProfilePhotoStore.loadPath(for: draftVendorID),
               let image = UIImage(contentsOfFile: path) {
                previewImage = image
            }
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }
            if let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                previewImage = image
                _ = VendorProfilePhotoStore.save(image, for: draftVendorID)
            }
        }
    }
}

#Preview {
    VendorNameView(viewModel: VendorOnboardingViewModel(), onContinue: {})
        .environment(\.locale, Locale(identifier: "en"))
}
