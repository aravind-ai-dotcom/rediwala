import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = AppTheme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title2.weight(.bold))
                }
                Text(title)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .foregroundStyle(.white)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCorner, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrimaryButton(title: "Explore", systemImage: "map.fill") {}
        .padding()
        .background(AppTheme.background)
}
