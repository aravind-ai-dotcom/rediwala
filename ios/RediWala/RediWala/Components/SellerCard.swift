import SwiftUI

struct SellerCard: View {
    let seller: Seller
    let isFavorite: Bool
    var showsFavoriteButton: Bool = true
    var onFavoriteToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                SellerAvatarView(
                    name: seller.name,
                    initials: seller.initials,
                    assetName: seller.profileImageAssetName,
                    remoteURL: seller.photoURL,
                    size: 64,
                    tint: avatarTint
                )

                if seller.isLive {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle().stroke(AppTheme.card, lineWidth: 2)
                        }
                        .offset(x: 2, y: 2)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(seller.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 8)

                    if showsFavoriteButton {
                        favoriteButton
                    }
                }

                Text(LocalizedStringKey(seller.category.localizationKey))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(LocalizedStringKey(seller.landmarkKey))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 10) {
                    Label(seller.formattedDistance, systemImage: "location.fill")
                    Label {
                        Text(LocalizedStringKey(seller.directionKey))
                    } icon: {
                        Image(systemName: "location.north.line.fill")
                    }

                    Text(seller.isLive ? "vendor.open" : "vendor.closed")
                        .fontWeight(.bold)
                        .foregroundStyle(seller.isLive ? AppTheme.primary : AppTheme.danger)

                    if seller.hasAnnouncement {
                        Image(systemName: "waveform")
                            .foregroundStyle(AppTheme.info)
                            .accessibilityLabel(Text("announcement.available"))
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }

    private var favoriteButton: some View {
        Button(action: onFavoriteToggle) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title3.weight(.bold))
                .foregroundStyle(isFavorite ? AppTheme.danger : AppTheme.textSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(isFavorite ? "vendorDetail.removeFavorite" : "vendorDetail.addFavorite")
        )
    }

    private var avatarTint: Color {
        switch seller.categoryGroup.tint {
        case .accent: return AppTheme.accent
        case .info: return AppTheme.info
        case .primary: return AppTheme.primary
        }
    }
}

#Preview("English") {
    SellerCard(
        seller: SyntheticChennaiData.sellers[0],
        isFavorite: true,
        onFavoriteToggle: {}
    )
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Tamil") {
    SellerCard(
        seller: SyntheticChennaiData.sellers[0],
        isFavorite: false,
        onFavoriteToggle: {}
    )
    .padding()
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "ta"))
}

#Preview("Dark") {
    SellerCard(
        seller: SyntheticChennaiData.sellers[1],
        isFavorite: false,
        onFavoriteToggle: {}
    )
    .padding()
    .preferredColorScheme(.dark)
    .background(AppTheme.background)
}
