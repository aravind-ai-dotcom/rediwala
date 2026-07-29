import MapKit
import SwiftUI

enum CustomerMapFilter: String, CaseIterable, Identifiable {
    case myVendors
    case live
    case nearby
    case todaysNeeds
    case favorites
    case all

    var id: String { rawValue }

    var titleKey: String { "map.filter.\(rawValue)" }
}

enum CustomerMapStyleOption: String, CaseIterable, Identifiable {
    case standard
    case satellite
    case hybrid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }
}

struct CustomerMapView: View {
    @ObservedObject var viewModel: CustomerMapViewModel
    @ObservedObject var favorites: FavoritesViewModel
    @ObservedObject var followStore: CustomerVendorFollowStore
    @ObservedObject var needsStore: CustomerNeedsStore
    var onShowList: () -> Void
    var onReturnHome: (() -> Void)? = nil

    @State private var filter: CustomerMapFilter = .myVendors
    @State private var mapStyle: CustomerMapStyleOption = .standard
    @State private var followMe = false

    private var visibleSellers: [Seller] {
        let base = viewModel.sellers
            .filter { $0.neighborhood == viewModel.selectedNeighborhood }
            .filter { !followStore.isHidden($0.id) }
        switch filter {
        case .all:
            return base
        case .myVendors:
            let ids = Set(followStore.myVendorIDs)
            let mine = base.filter { ids.contains($0.id) }
            if mine.isEmpty {
                return base
                    .filter(\.isEffectivelyLive)
                    .sorted { $0.distanceMeters < $1.distanceMeters }
                    .prefix(8)
                    .map { $0 }
            }
            return mine
        case .live:
            return base.filter(\.isEffectivelyLive)
        case .nearby:
            return base.sorted { $0.distanceMeters < $1.distanceMeters }.prefix(12).map { $0 }
        case .todaysNeeds:
            let cats = needsStore.matchingCategories
            return base.filter { cats.contains($0.category) }
        case .favorites:
            return base.filter { favorites.isFavorite($0.id) }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $viewModel.cameraPosition) {
                ForEach(visibleSellers) { seller in
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
            .mapStyle(mapStyle.mapStyle)
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
                MapUserLocationButton()
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                topControls
                filterBar
                Spacer(minLength: 0)
                if visibleSellers.isEmpty {
                    emptyCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                } else if let seller = viewModel.selectedSeller ?? visibleSellers.first {
                    sellerPreview(seller)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
        .task { await viewModel.load(recenterIfNeeded: true) }
        .onChange(of: filter) { _, _ in
            if let first = visibleSellers.first {
                viewModel.selectSeller(first.id)
            } else {
                viewModel.selectSeller(nil)
            }
        }
    }

    private var topControls: some View {
        HStack {
            neighborhoodPill
            Spacer(minLength: 8)
            Menu {
                Picker("Style", selection: $mapStyle) {
                    ForEach(CustomerMapStyleOption.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
            } label: {
                controlGlyph("map")
            }
            controlButton(systemImage: "list.bullet", labelKey: "home.mode.dashboard", action: onShowList)
            controlButton(systemImage: followMe ? "location.fill" : "location", labelKey: "map.follow_me") {
                followMe.toggle()
                if followMe { viewModel.recenter() }
            }
            controlButton(systemImage: "house.fill", labelKey: "home.return_home") {
                followMe = false
                onReturnHome?()
                viewModel.recenter()
            }
            controlButton(systemImage: "scope", labelKey: "map.recenter") {
                followMe = false
                viewModel.recenter()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var neighborhoodPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(AppTheme.textPrimary)
            Text(LocalizedStringKey(viewModel.selectedNeighborhood.nameKey))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.subheadline.weight(.bold))
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(AppTheme.card.opacity(0.95))
        .clipShape(Capsule())
        .accessibilityLabel(Text("map.neighborhood"))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CustomerMapFilter.allCases) { item in
                    Button {
                        filter = item
                    } label: {
                        Text(LocalizedStringKey(item.titleKey))
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 36)
                            .foregroundStyle(filter == item ? .white : AppTheme.textPrimary)
                            .background(filter == item ? AppTheme.primary : AppTheme.card.opacity(0.95))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("map.empty.live.title")
                .font(.headline.weight(.bold))
            Text("map.empty.live.subtitle")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 8) {
                Button("map.empty.notify") {}
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                Button("map.empty.scheduled") { filter = .nearby }
                    .buttonStyle(.bordered)
                Button("map.empty.browse") { filter = .all }
                    .buttonStyle(.bordered)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    // Neighborhood switching removed from map to keep the experience local by default.

    private func controlButton(systemImage: String, labelKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            controlGlyph(systemImage)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(labelKey)))
    }

    private func controlGlyph(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.bold))
            .foregroundStyle(AppTheme.primary)
            .frame(width: 44, height: 44)
            .background(AppTheme.card.opacity(0.95))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }

    private func mapPin(for seller: Seller) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(seller.isEffectivelyLive ? AppTheme.primary : AppTheme.info)
                    .frame(width: 36, height: 36)
                Image(systemName: seller.category.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            Text(seller.isEffectivelyLive ? "LIVE" : "•")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(AppTheme.card)
                .clipShape(Capsule())
        }
    }

    private func sellerPreview(_ seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                SellerAvatarView(
                    name: seller.name,
                    initials: seller.initials,
                    assetName: seller.profileImageAssetName,
                    remoteURL: seller.photoURL,
                    size: 48,
                    tint: AppTheme.primary
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(seller.name).font(.headline.weight(.bold))
                    Text(LocalizedStringKey(seller.category.localizationKey))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    if let progress = seller.progressLabel {
                        Text(progress)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                Spacer()
                Text(seller.etaLabel ?? seller.formattedDistance)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }

            HStack(spacing: 8) {
                Button {
                    followStore.toggleFollow(seller.id)
                } label: {
                    Label(followStore.isFollowing(seller.id) ? "Tracking" : "Track", systemImage: "bell.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)

                Button {
                    favorites.toggle(seller.id)
                } label: {
                    Image(systemName: favorites.isFavorite(seller.id) ? "heart.fill" : "heart")
                }
                .buttonStyle(.bordered)

                NavigationLink {
                    VendorDetailView(vendorID: seller.id)
                } label: {
                    Text("Open")
                }
                .buttonStyle(.bordered)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(14)
        .background(AppTheme.card.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}
