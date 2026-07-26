import SwiftUI

struct SectionHeader: View {
    let titleKey: String
    var subtitleKey: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(titleKey))
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if let subtitleKey {
                Text(LocalizedStringKey(subtitleKey))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SectionHeader(titleKey: "home.summary.title", subtitleKey: "home.summary.subtitle")
        .padding()
        .background(AppTheme.background)
        .environment(\.locale, Locale(identifier: "en"))
}
