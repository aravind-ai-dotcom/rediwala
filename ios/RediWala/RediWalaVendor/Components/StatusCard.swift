import SwiftUI

struct StatusCard: View {
    let title: String
    var isLive: Bool = false

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if isLive {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.25))
                        .frame(width: 88, height: 88)
                        .scaleEffect(pulse ? 1.25 : 0.9)
                        .opacity(pulse ? 0.2 : 0.7)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                            value: pulse
                        )
                }

                Image(systemName: isLive ? "dot.radiowaves.left.and.right" : "moon.zzz.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(isLive ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(width: 72, height: 72)
                    .background(
                        Circle()
                            .fill(isLive ? AppTheme.primary.opacity(0.15) : AppTheme.background)
                    )
            }

            Text(title)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(isLive ? AppTheme.primary : AppTheme.textPrimary)
                .accessibilityLabel(title)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .onAppear { pulse = isLive }
        .onChange(of: isLive) { _, newValue in
            pulse = newValue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusCard(title: "OFFLINE", isLive: false)
        StatusCard(title: "LIVE", isLive: true)
    }
    .padding()
    .background(AppTheme.background)
}
