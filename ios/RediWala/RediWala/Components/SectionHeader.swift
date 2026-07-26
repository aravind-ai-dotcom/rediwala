import SwiftUI

struct SectionHeader: View {
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey? = nil
    var actionTitleKey: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleKey)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitleKey {
                    Text(subtitleKey)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            if let actionTitleKey, let action {
                Button(action: action) {
                    Text(actionTitleKey)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.info)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        SectionHeader(titleKey: "home.nearbyNow")
        SectionHeader(titleKey: "seller.myDay", subtitleKey: "seller.myDay.subtitle")
    }
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
