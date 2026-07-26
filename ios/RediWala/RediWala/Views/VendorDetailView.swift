import MapKit
import SwiftUI

struct VendorDetailView: View {
    let vendorID: String
    @EnvironmentObject private var favorites: FavoritesViewModel
    @State private var seller: Seller?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let seller {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(for: seller)
                        aboutCard(for: seller)
                        infoRows(for: seller)

                        if seller.hasAnnouncement {
                            AnnouncementPlayerView(
                                sellerName: seller.name,
                                durationSeconds: seller.announcementDurationSeconds
                            )
                        }

                        myDaySection(for: seller)
                        mapPreview(for: seller)
                        actionPlaceholders
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView {
                    Label {
                        Text("vendorDetail.notFound.title")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                } description: {
                    Text("vendorDetail.notFound.subtitle")
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(seller?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if seller != nil {
                    Button {
                        favorites.toggle(vendorID)
                    } label: {
                        Image(systemName: favorites.isFavorite(vendorID) ? "heart.fill" : "heart")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(favorites.isFavorite(vendorID) ? AppTheme.danger : AppTheme.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(
                        Text(favorites.isFavorite(vendorID) ? "vendorDetail.removeFavorite" : "vendorDetail.addFavorite")
                    )
                }
            }
        }
        .task {
            isLoading = true
            seller = await favorites.repository.fetchSeller(id: vendorID)
            isLoading = false
        }
    }

    @ViewBuilder
    private func header(for seller: Seller) -> some View {
        VStack(spacing: 16) {
            SellerAvatarView(
                name: seller.name,
                initials: seller.initials,
                assetName: seller.profileImageAssetName,
                size: 120,
                tint: AppTheme.primary
            )

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(seller.name)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let business = seller.businessName {
                        Text(business)
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Text(LocalizedStringKey(seller.category.localizationKey))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(AppTheme.accent)
                        Text(String(format: "%.1f", seller.rating))
                            .font(.title3.weight(.bold))
                    }

                    Text(seller.isLive ? "vendor.open" : "vendor.closed")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(seller.isLive ? AppTheme.primary : AppTheme.danger)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((seller.isLive ? AppTheme.primary : AppTheme.danger).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Button {
                favorites.toggle(seller.id)
            } label: {
                Label {
                    Text(
                        favorites.isFavorite(seller.id)
                            ? "vendorDetail.removeFavorite"
                            : "vendorDetail.addFavorite"
                    )
                } icon: {
                    Image(systemName: favorites.isFavorite(seller.id) ? "heart.slash.fill" : "heart.fill")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(favorites.isFavorite(seller.id) ? AppTheme.danger : .white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(favorites.isFavorite(seller.id) ? AppTheme.danger.opacity(0.12) : AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func aboutCard(for seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("vendorDetail.about")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(LocalizedStringKey(seller.descriptionKey))
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
    }

    private func infoRows(for seller: Seller) -> some View {
        VStack(spacing: 12) {
            ProfileRow(
                titleKey: "vendorDetail.distance",
                value: "\(seller.formattedDistance) · \(String(localized: String.LocalizationValue(seller.directionKey)))",
                systemImage: "location.fill"
            )
            ProfileRow(
                titleKey: "vendorDetail.area",
                value: "\(String(localized: String.LocalizationValue(seller.landmarkKey))), \(String(localized: String.LocalizationValue(seller.neighborhood.nameKey)))",
                systemImage: "mappin.and.ellipse"
            )
            ProfileRow(
                titleKey: "vendorDetail.languages",
                value: seller.languages
                    .map { String(localized: String.LocalizationValue($0.localizationKey)) }
                    .joined(separator: ", "),
                systemImage: "globe"
            )
            ProfileRow(
                titleKey: "vendorDetail.hours",
                value: seller.workingHours,
                systemImage: "clock.fill"
            )
        }
    }

    private func myDaySection(for seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(titleKey: "seller.myDay", subtitleKey: "seller.myDay.subtitle")

            RouteTimelineView(stops: seller.routeStops)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        }
    }

    private func mapPreview(for seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("seller.map_preview")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: seller.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            ) {
                Marker(seller.name, coordinate: seller.coordinate)
                    .tint(AppTheme.primary)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
            .allowsHitTesting(false)
            .accessibilityLabel(Text("seller.map_preview"))
        }
    }

    private var actionPlaceholders: some View {
        HStack(spacing: 12) {
            placeholderButton(titleKey: "seller.directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
            placeholderButton(titleKey: "seller.call", systemImage: "phone.fill")
        }
    }

    private func placeholderButton(titleKey: String, systemImage: String) -> some View {
        Button {} label: {
            Label {
                Text(LocalizedStringKey(titleKey))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } icon: {
                Image(systemName: systemImage)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(AppTheme.primary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(true)
        .opacity(0.85)
        .accessibilityLabel(Text(LocalizedStringKey(titleKey)))
        .accessibilityHint(Text("common.coming_soon_action"))
    }
}

#Preview("English") {
    let repo = LocalSellerRepository()
    return NavigationStack {
        VendorDetailView(vendorID: "murugan")
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Tamil Dark") {
    let repo = LocalSellerRepository()
    return NavigationStack {
        VendorDetailView(vendorID: "lakshmi")
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .preferredColorScheme(.dark)
    .environment(\.locale, Locale(identifier: "ta"))
}
