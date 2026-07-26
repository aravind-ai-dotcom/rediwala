import SwiftUI

enum PrimaryButtonStyle {
    case primary
    case danger
    case accent
}

struct PrimaryButton: View {
    let titleKey: String
    var systemImage: String? = nil
    var style: PrimaryButtonStyle = .primary
    var isEnabled: Bool = true
    var prominent: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title2.weight(.bold))
                        .symbolRenderingMode(.hierarchical)
                }
                Text(LocalizedStringKey(titleKey))
                    .font(.title2.weight(.bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: prominent ? 72 : AppTheme.minTap)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [backgroundColor, backgroundColor.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCorner, style: .continuous))
            .shadow(
                color: backgroundColor.opacity(isEnabled ? 0.35 : 0),
                radius: prominent ? 16 : 10,
                y: prominent ? 8 : 4
            )
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard isEnabled else { return }
                    isPressed = true
                }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(Text(LocalizedStringKey(titleKey)))
        .accessibilityAddTraits(.isButton)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return AppTheme.primary
        case .danger: return AppTheme.danger
        case .accent: return AppTheme.accent
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(titleKey: "home.go_live", systemImage: "antenna.radiowaves.left.and.right", prominent: true) {}
        PrimaryButton(titleKey: "live.stop", systemImage: "stop.fill", style: .danger) {}
    }
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
