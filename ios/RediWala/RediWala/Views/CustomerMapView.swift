import MapKit
import SwiftUI

struct CustomerMapView: View {
    @ObservedObject var viewModel: CustomerMapViewModel
    @ObservedObject var favorites: FavoritesViewModel
    var onShowList: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.sellers) { seller in
                    Annotation(seller.name, coordinate: seller.coordinate, anchor: .bottom) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectSeller(seller.id)
                            }
                        } label: {
                            mapPin(for: seller)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(seller.name))
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                HStack {
                    neighborhoodPicker
                    Spacer(minLength: 8)
                    controlButton(systemImage: "list.bullet", labelKey: "home.mode.list", action: onShowList)
                    controlButton(systemImage: "location.circle.fill", labelKey: "map.recenter") {
                        viewModel.recenter()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer(minLength: 0)

                if let seller = viewModel.selectedSeller {
                    sellerPreview(seller)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var neighborhoodPicker: some View {
        Menu {
            ForEach(PilotNeighborhood.allCases) { neighborhood in
                Button {
                    viewModel.selectNeighborhood(neighborhood)
                } label: {
                    Text(LocalizedStringKey(neighborhood.nameKey))
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                Text(LocalizedStringKey(viewModel.selectedNeighborhood.nameKey))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(AppTheme.card.opacity(0.95))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        }
        .accessibilityLabel(Text("map.neighborhood"))
    }

    private func controlButton(systemImage: String, labelKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 44, height: 44)
                .background(AppTheme.card.opacity(0.95))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(labelKey)))
    }

    private func mapPin(for seller: Seller) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(seller.isLive ? AppTheme.primary : AppTheme.card)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                Image(systemName: seller.category.systemImage)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(seller.isLive ? .white : AppTheme.primary)
            }

            if seller.isLive {
                Text("vendor.open")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private func sellerPreview(_ seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SellerAvatarView(
                    name: seller.name,
                    initials: seller.initials,
                    assetName: seller.profileImageAssetName,
                    size: 52
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(seller.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(LocalizedStringKey(seller.category.localizationKey))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(seller.formattedDistance)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 0)

                Button {
                    favorites.toggle(seller.id)
                } label: {
                    Image(systemName: favorites.isFavorite(seller.id) ? "heart.fill" : "heart")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(favorites.isFavorite(seller.id) ? AppTheme.danger : AppTheme.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(favorites.isFavorite(seller.id) ? "vendorDetail.removeFavorite" : "vendorDetail.addFavorite")
                )
            }

            NavigationLink {
                VendorDetailView(vendorID: seller.id)
            } label: {
                Text("map.view_details")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .foregroundStyle(.white)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }
}

#Preview("Map English") {
    let repo = LocalSellerRepository()
    return NavigationStack {
        CustomerMapView(
            viewModel: CustomerMapViewModel(repository: repo),
            favorites: FavoritesViewModel(repository: repo),
            onShowList: {}
        )
    }
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Map Tamil Dark") {
    let repo = LocalSellerRepository()
    return NavigationStack {
        CustomerMapView(
            viewModel: CustomerMapViewModel(repository: repo),
            favorites: FavoritesViewModel(repository: repo),
            onShowList: {}
        )
    }
    .preferredColorScheme(.dark)
    .environment(\.locale, Locale(identifier: "ta"))
}
