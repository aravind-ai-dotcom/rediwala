import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("🛺")
                .font(.system(size: 72))
                .accessibilityHidden(true)

            Text("REDIWALA")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(AppTheme.primary)
                .tracking(1.5)

            Text("Fresh Street Markets")
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.primary)
                .padding(.top, 28)
                .accessibilityLabel("Loading")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    SplashView()
}
