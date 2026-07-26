import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("onboarding.language.title")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("onboarding.language.subtitle")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { language in
                        LargeActionButton(
                            titleKey: LocalizedStringKey(language.localizationKey),
                            subtitleKey: language == .english
                                ? "onboarding.language.englishSubtitle"
                                : "onboarding.language.tamilSubtitle",
                            systemImage: language == .english ? "globe" : "character.book.closed",
                            isSelected: languageStore.language == language
                        ) {
                            languageStore.select(language)
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(titleKey: "onboarding.language.continue", systemImage: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    LanguageSelectionView(onContinue: {})
        .environmentObject(AppLanguageStore())
        .environment(\.locale, Locale(identifier: "en"))
}
