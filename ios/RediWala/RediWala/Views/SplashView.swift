import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("🛺")
                .font(.system(size: 72))
                .accessibilityHidden(true)

            Text("splash.brand")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(AppTheme.primary)
                .tracking(1.5)

            Text("splash.tagline")
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.primary)
                .padding(.top, 28)
                .accessibilityLabel(Text("accessibility.loading"))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    SplashView()
        .environment(\.locale, Locale(identifier: "en"))
}
