import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("settings.language")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("settings.language.subtitle")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
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
                            viewModel.selectLanguage(language, store: languageStore)
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AppLanguageStore())
    .environment(\.locale, Locale(identifier: "en"))
}
