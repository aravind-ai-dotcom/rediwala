import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: FirebaseAuthService

    var body: some View {
        Group {
            switch authService.state {
            case .loading:
                SplashView()

            case .signedIn:
                VendorRootView()

            case .failed(let message):
                VStack(spacing: 24) {
                    Text("🛺")
                        .font(.system(size: 64))
                    Text("REDIWALA")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.primary)
                    Text(message)
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background.ignoresSafeArea())
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseAuthService())
}
