import SwiftUI

struct BusinessCategoryView: View {
    @ObservedObject var viewModel: VendorOnboardingViewModel
    var onContinue: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                SectionHeader(
                    titleKey: "onboarding.category.title",
                    subtitleKey: "onboarding.category.subtitle"
                )

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(VendorCategory.allCases) { category in
                        Button {
                            viewModel.selectedCategory = category
                        } label: {
                            CategoryCard(
                                titleKey: category.titleKey,
                                systemImage: category.systemImage,
                                tint: tint(for: category),
                                isSelected: viewModel.selectedCategory == category
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(titleKey: "common.continue", systemImage: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func tint(for category: VendorCategory) -> Color {
        switch category.tintName {
        case "accent": return AppTheme.accent
        case "info": return AppTheme.info
        default: return AppTheme.primary
        }
    }
}

#Preview {
    BusinessCategoryView(viewModel: VendorOnboardingViewModel(), onContinue: {})
        .environment(\.locale, Locale(identifier: "en"))
}
