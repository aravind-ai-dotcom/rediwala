import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: FirebaseAuthService

    var body: some View {
        Group {
            switch authService.state {
            case .loading:
                Text("Loading...")
                    .font(.title2)

            case .signedIn(let uid):
                VStack(spacing: 12) {
                    Text("Vendor Logged In")
                        .font(.title2)
                    Text(uid)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

            case .failed(let message):
                VStack(spacing: 12) {
                    Text("Sign-in failed")
                        .font(.title2)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseAuthService())
}
