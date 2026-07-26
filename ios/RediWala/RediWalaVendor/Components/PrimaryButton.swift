import SwiftUI

enum PrimaryButtonStyle {
    case primary
    case danger
}

struct PrimaryButton: View {
    let title: String
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
                Text(title)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
        case .danger: return AppTheme.danger
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "GO LIVE", systemImage: "antenna.radiowaves.left.and.right") {}
        PrimaryButton(title: "STOP", systemImage: "stop.fill", style: .danger) {}
    }
    .padding()
    .background(AppTheme.background)
}
