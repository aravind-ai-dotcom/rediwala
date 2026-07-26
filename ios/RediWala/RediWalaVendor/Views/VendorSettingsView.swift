import SwiftUI

struct VendorSettingsView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    SectionHeader(
                        titleKey: "settings.language_section",
                        subtitleKey: "settings.language_hint"
                    )

                    VStack(spacing: 12) {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                languageStore.select(language)
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(language.selectionKey))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.85)
                                    Spacer()
                                    if languageStore.selected == language {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.primary)
                                    }
                                }
                                .padding(16)
                                .frame(minHeight: AppTheme.minTap)
                                .background(AppTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SectionHeader(titleKey: "settings.about_section")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.about_body")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(5)
                            .minimumScaleFactor(0.85)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(Text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.done")
                    }
                    .accessibilityLabel(Text("common.done"))
                }
            }
        }
    }
}

#Preview {
    VendorSettingsView()
        .environmentObject(AppLanguageStore())
        .environment(\.locale, Locale(identifier: "en"))
}
