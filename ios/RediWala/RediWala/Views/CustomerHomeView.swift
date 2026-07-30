import MapKit
import SwiftUI

struct CustomerHomeView: View {
    @ObservedObject var viewModel: CustomerHomeViewModel
    @EnvironmentObject private var favorites: FavoritesViewModel
    @ObservedObject private var geo = GeoContext.shared

    private let cardLimit = 3

    var body: some View {
        Group {
            if viewModel.browseMode == .map {
                CustomerMapView(
                    viewModel: viewModel.mapViewModel,
                    favorites: favorites,
                    followStore: viewModel.followStore,
                    needsStore: viewModel.needsStore,
                    onShowList: { viewModel.browseMode = .list },
                    onReturnHome: { viewModel.returnHomeArea() }
                )
            } else {
                dashboard
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text(LocalizedText.resolve("home.dashboard.title", fallback: "My Neighborhood")))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showNeedsEditor) {
            NavigationStack {
                NeedsSelectionView(onDone: { viewModel.showNeedsEditor = false })
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                mapHero
                expectedSoonSection
                nearbyTimelineSection
                todaysNeedsCompact
                if !viewModel.bestMatches.isEmpty {
                    bestMatchesCompact
                }
                watchListSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var mapHero: some View {
        Button {
            viewModel.openMap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                Map(position: .constant(geo.cameraPosition)) {
                    ForEach(Array(viewModel.nearbyRightNow.prefix(5))) { seller in
                        Annotation(seller.name, coordinate: seller.coordinate) {
                            Circle()
                                .fill(seller.isEffectivelyLive ? AppTheme.primary : AppTheme.info)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(viewModel.selectedNeighborhood.nameKey))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Open map")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(12)
                .background(.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(12)
            }
        }
        .buttonStyle(.plain)
    }

    private var todaysNeedsCompact: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Needs")
                    .font(.headline.weight(.bold))
                Spacer()
                Button("Edit") { viewModel.showNeedsEditor = true }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.info)
            }

            if viewModel.needsStore.activeNeeds.isEmpty {
                Button {
                    viewModel.showNeedsEditor = true
                } label: {
                    Text("Choose today's needs")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .foregroundStyle(.white)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.needsStore.activeNeeds) { need in
                            HStack(spacing: 6) {
                                Image(systemName: need.systemImage)
                                Text(LocalizedStringKey(need.titleKey))
                                    .lineLimit(1)
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .frame(minHeight: 34)
                            .background(AppTheme.card)
                            .overlay { Capsule().stroke(AppTheme.primary.opacity(0.3), lineWidth: 1) }
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var expectedSoonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expected Soon")
                .font(.headline.weight(.bold))
            let items = Array(viewModel.expectedSoon.prefix(cardLimit))
            if items.isEmpty {
                Text("No upcoming arrivals nearby")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(items) { seller in
                    NavigationLink {
                        VendorDetailView(vendorID: seller.id)
                    } label: {
                        ExpectedSoonRow(seller: seller)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var nearbyTimelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Nearby")
                    .font(.headline.weight(.bold))
                Spacer()
                Button("Map") { viewModel.openMap() }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.info)
            }
            let items = Array(viewModel.nearbyRightNow.prefix(cardLimit))
            if items.isEmpty {
                Text("No one live nearby right now")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(items) { seller in
                    NavigationLink {
                        VendorDetailView(vendorID: seller.id)
                    } label: {
                        NearbyTimelineRow(seller: seller) {
                            viewModel.followStore.track(seller.id)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var bestMatchesCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Matches")
                .font(.headline.weight(.bold))
            ForEach(Array(viewModel.bestMatches.prefix(2))) { seller in
                NavigationLink {
                    VendorDetailView(vendorID: seller.id)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: seller.category.systemImage)
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(seller.name)
                                .font(.subheadline.weight(.bold))
                            Text("\(LocalizedStringKey(seller.category.localizationKey)) · \(seller.formattedDistance)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(LocalizedText.resolve("home.why_match", fallback: "Matches today's needs"))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.info)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var watchListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedText.resolve("watchlist.title", fallback: "Today's Watch List"))
                .font(.headline.weight(.bold))
            let items = Array(viewModel.myVendors.prefix(cardLimit))
            if items.isEmpty {
                Text(LocalizedText.resolve("watchlist.empty", fallback: "Nothing to watch yet"))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(items) { seller in
                    NavigationLink {
                        VendorDetailView(vendorID: seller.id)
                    } label: {
                        HStack {
                            Text(seller.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(seller.isEffectivelyLive ? "Live" : "Soon")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(seller.isEffectivelyLive ? AppTheme.primary : AppTheme.info)
                        }
                        .padding(12)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct NearbyTimelineRow: View {
    let seller: Seller
    var onTrack: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(AppTheme.primary)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(AppTheme.primary.opacity(0.25))
                    .frame(width: 2, height: 28)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(seller.category.localizationKey))
                    .font(.subheadline.weight(.bold))
                Text(seller.streetName
                      ?? LocalizedText.resolve(seller.landmarkKey, fallback: seller.name))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(seller.formattedDistance)
                    .font(.caption.weight(.bold))
                Button("Track") { onTrack?() }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ExpectedSoonRow: View {
    let seller: Seller

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(AppTheme.info)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(AppTheme.info.opacity(0.25))
                    .frame(width: 2, height: 28)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(seller.routeStops.first(where: { $0.status == .upcoming })?.timeLabel ?? "—")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.info)
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(seller.category.localizationKey))
                    Text("·")
                    Text(seller.name)
                }
                .font(.subheadline.weight(.bold))
                if let stop = seller.routeStops.first(where: { $0.status == .upcoming }) {
                    Text(LocalizedText.resolve(stop.titleKey, fallback: "Upcoming stop"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(seller.formattedDistance)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
