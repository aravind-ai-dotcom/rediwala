import SwiftUI

struct StatusCard: View {
    let titleKey: LocalizedStringKey
    var isLive: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isLive ? "dot.radiowaves.left.and.right" : "moon.zzz.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(isLive ? AppTheme.primary : AppTheme.textSecondary)
                .frame(width: 72, height: 72)
                .background(
                    Circle().fill(isLive ? AppTheme.primary.opacity(0.15) : AppTheme.background)
                )

            Text(titleKey)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(isLive ? AppTheme.primary : AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

#Preview {
    StatusCard(titleKey: "vendor.closed")
        .padding()
        .background(AppTheme.background)
        .environment(\.locale, Locale(identifier: "en"))
}
