import SwiftUI

struct CustomerContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 52))

            Text("RediWala")
                .font(.largeTitle.bold())

            Text("Customer App")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    CustomerContentView()
}
