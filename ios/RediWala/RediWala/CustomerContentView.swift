import SwiftUI

struct CustomerContentView: View {
    @State private var showHome = false

    var body: some View {
        Group {
            if showHome {
                CustomerHomeView()
                    .transition(.opacity)
            } else {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showHome)
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            showHome = true
        }
    }
}

#Preview {
    CustomerContentView()
}
