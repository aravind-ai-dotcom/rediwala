import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                SectionHeader(
                    titleKey: "language.title",
                    subtitleKey: "language.subtitle"
                )

                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { language in
                        languageRow(language)
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

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            languageStore.select(language)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: language == .english ? "character.book.closed.fill" : "textformat")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.info)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.info.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(LocalizedStringKey(language.selectionKey))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                if languageStore.selected == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .padding(16)
            .frame(minHeight: AppTheme.minTap)
            .background(AppTheme.card)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                    .stroke(languageStore.selected == language ? AppTheme.primary : Color.clear, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(languageStore.selected == language ? .isSelected : [])
    }
}

#Preview {
    LanguageSelectionView(onContinue: {})
        .environmentObject(AppLanguageStore())
        .environment(\.locale, Locale(identifier: "en"))
}
