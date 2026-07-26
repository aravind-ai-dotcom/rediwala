import SwiftUI

struct StatusCard: View {
    let titleKey: String
    var isLive: Bool = false

    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("status.current")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(spacing: 16) {
                ZStack {
                    if isLive {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.25))
                            .frame(width: 72, height: 72)
                            .scaleEffect(pulse ? 1.2 : 0.95)
                            .opacity(pulse ? 0.25 : 0.7)
                            .animation(
                                .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                                value: pulse
                            )
                    }

                    Image(systemName: isLive ? "dot.radiowaves.left.and.right" : "moon.zzz.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(isLive ? AppTheme.primary : AppTheme.textSecondary)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: isLive
                                            ? [AppTheme.primary.opacity(0.22), AppTheme.primary.opacity(0.08)]
                                            : [AppTheme.background, AppTheme.card],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(isLive ? AppTheme.primary : AppTheme.danger)
                            .frame(width: 12, height: 12)
                            .shadow(color: (isLive ? AppTheme.primary : AppTheme.danger).opacity(0.45), radius: 4, y: 1)

                        Text(LocalizedStringKey(titleKey))
                            .font(.title.weight(.heavy))
                            .foregroundStyle(isLive ? AppTheme.primary : AppTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Text(LocalizedStringKey(isLive ? "status.live_hint" : "status.offline_hint"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    (isLive ? AppTheme.primary : Color.primary).opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.07), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
        .onAppear { pulse = isLive }
        .onChange(of: isLive) { _, newValue in
            pulse = newValue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusCard(titleKey: "status.offline", isLive: false)
        StatusCard(titleKey: "status.live", isLive: true)
    }
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
