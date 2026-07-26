import SwiftUI

enum PrimaryButtonStyle {
    case primary
    case accent
    case danger
}

struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    var systemImage: String? = nil
    var style: PrimaryButtonStyle = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title2.weight(.bold))
                        .symbolRenderingMode(.hierarchical)
                }
                Text(titleKey)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .foregroundStyle(.white)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCorner, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(.isButton)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return AppTheme.primary
        case .accent: return AppTheme.accent
        case .danger: return AppTheme.danger
        }
    }
}

#Preview {
    PrimaryButton(titleKey: "onboarding.language.continue", systemImage: "arrow.right") {}
        .padding()
        .background(AppTheme.background)
        .environment(\.locale, Locale(identifier: "en"))
}
