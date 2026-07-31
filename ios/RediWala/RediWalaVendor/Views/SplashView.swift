import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
                .accessibilityHidden(true)

            Text(LocalizedText.resolve("app.name", fallback: "RediWala"))
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(AppTheme.primary)
                .tracking(0.8)

            Text(LocalizedText.resolve("app.tagline", fallback: "Reach your neighborhood."))
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.primary)
                .padding(.top, 24)
                .accessibilityLabel(Text(LocalizedText.resolve("accessibility.loading", fallback: "Loading")))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55)) {
                opacity = 1
            }
        }
    }
}

#Preview {
    SplashView()
        .environment(\.locale, Locale(identifier: "en"))
}
