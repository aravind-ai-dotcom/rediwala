import SwiftUI
import UIKit

struct SellerAvatarView: View {
    let name: String
    let initials: String
    var assetName: String? = nil
    var remoteURL: String? = nil
    var size: CGFloat = 56
    var tint: Color = AppTheme.primary

    var body: some View {
        Group {
            if let remoteURL,
               let url = URL(string: remoteURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        initialsFallback
                    }
                }
            } else if let assetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                initialsFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var initialsFallback: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.25), tint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        SellerAvatarView(name: "Murugan", initials: "M", size: 72)
        SellerAvatarView(name: "Lakshmi", initials: "L", size: 56, tint: AppTheme.accent)
        SellerAvatarView(name: "Ramesh", initials: "R", size: 44, tint: AppTheme.info)
    }
    .padding()
    .background(AppTheme.background)
}
