import SwiftUI

struct CustomerHomeView: View {
    @ObservedObject var viewModel: CustomerHomeViewModel
    @EnvironmentObject private var favorites: FavoritesViewModel

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
        .navigationTitle(Text("home.dashboard.title"))
        .navigationBarTitleDisplayMode(viewModel.browseMode == .map ? .inline : .large)
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showNeedsEditor) {
            NavigationStack {
                NeedsSelectionView(onDone: { viewModel.showNeedsEditor = false })
            }
            .presentationDetents([.large])
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                todaysNeedsEpicenter
                bestMatchesSection
                nearbySection
                expectedSoonSection
                myVendorsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.visible)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(viewModel.greetingKey))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(LocalizedStringKey(viewModel.selectedNeighborhood.nameKey))
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer(minLength: 0)

            Button {
                viewModel.openMap()
            } label: {
                Image(systemName: "map.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("home.open_map"))
        }
    }

    private var todaysNeedsEpicenter: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("home.what_do_you_need")
                .font(.title.weight(.heavy))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.needsStore.activeNeeds.isEmpty {
                Text("home.todays_needs.empty_hint")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Button {
                    viewModel.showNeedsEditor = true
                } label: {
                    Text("home.choose_todays_needs")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 40)
                            .background(AppTheme.card)
                            .overlay {
                                Capsule().stroke(AppTheme.primary.opacity(0.35), lineWidth: 1.5)
                            }
                            .clipShape(Capsule())
                        }
                    }
                }

                Button {
                    viewModel.showNeedsEditor = true
                } label: {
                    Text("home.edit_todays_needs")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.info)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var bestMatchesSection: some View {
        vendorRail(
            titleKey: "home.best_matches",
            subtitleKey: "home.best_matches.subtitle",
            sellers: Array(viewModel.bestMatches.prefix(cardLimit)),
            emptyKey: "home.best_matches.empty",
            actionTitleKey: viewModel.bestMatches.count > cardLimit ? "home.best_matches.see_all" : nil,
            action: { viewModel.openMap() }
        )
    }

    private var nearbySection: some View {
        vendorRail(
            titleKey: "home.nearby_now",
            subtitleKey: "home.nearby_now.subtitle",
            sellers: Array(viewModel.nearbyRightNow.prefix(cardLimit)),
            emptyKey: "home.nearby_now.empty",
            actionTitleKey: "home.open_map",
            action: { viewModel.openMap() }
        )
    }

    private var expectedSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                titleKey: "home.expected_soon",
                subtitleKey: "home.expected_soon.subtitle"
            )
            let items = Array(viewModel.expectedSoon.prefix(cardLimit))
            if items.isEmpty {
                Text("home.expected_soon.empty")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                VStack(spacing: 10) {
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
    }

    private var myVendorsSection: some View {
        vendorRail(
            titleKey: "home.my_vendors",
            subtitleKey: "home.my_vendors.subtitle",
            sellers: Array(viewModel.myVendors.prefix(cardLimit)),
            emptyKey: "home.my_vendors.empty",
            actionTitleKey: viewModel.myVendors.count > cardLimit ? "home.my_vendors.see_all" : nil,
            action: { viewModel.openMap() }
        )
    }

    private func vendorRail(
        titleKey: String,
        subtitleKey: String,
        sellers: [Seller],
        emptyKey: String,
        actionTitleKey: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                titleKey: LocalizedStringKey(titleKey),
                subtitleKey: LocalizedStringKey(subtitleKey),
                actionTitleKey: actionTitleKey.map { LocalizedStringKey($0) },
                action: action
            )
            if sellers.isEmpty {
                Text(LocalizedStringKey(emptyKey))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sellers) { seller in
                            NavigationLink {
                                VendorDetailView(vendorID: seller.id)
                            } label: {
                                CompactVendorCard(
                                    seller: seller,
                                    onTrack: { viewModel.followStore.track(seller.id) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct CompactVendorCard: View {
    let seller: Seller
    var onTrack: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                SellerAvatarView(
                    name: seller.name,
                    initials: seller.initials,
                    assetName: seller.profileImageAssetName,
                    remoteURL: seller.photoURL,
                    size: 44,
                    tint: categoryTint
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(seller.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(LocalizedStringKey(seller.category.localizationKey))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            Text(statusLine)
                .font(.caption.weight(.semibold))
                .foregroundStyle(seller.isEffectivelyLive ? AppTheme.primary : AppTheme.textSecondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Button {
                    onTrack?()
                } label: {
                    Text("vendor.track")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)

                Text("vendor.message")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36)
                    .foregroundStyle(AppTheme.textSecondary)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var statusLine: String {
        if seller.isEffectivelyLive {
            return "\(String(localized: "vendor.status.live")) · \(seller.etaLabel ?? seller.formattedDistance)"
        }
        return seller.etaLabel ?? String(localized: "home.expected_within")
    }

    private var categoryTint: Color {
        switch seller.categoryGroup {
        case .freshDaily: return AppTheme.primary
        case .neighborhoodServices: return AppTheme.info
        case .homeDelivery: return AppTheme.accent
        case .recyclingBuyers: return AppTheme.accent
        case .streetTreats: return AppTheme.accent
        }
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
                    .frame(width: 2, height: 30)
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
                .foregroundStyle(AppTheme.textPrimary)
                if let stop = seller.routeStops.first(where: { $0.status == .upcoming }) {
                    Text(LocalizedStringKey(stop.titleKey))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(seller.progressLabel ?? String(localized: "home.expected_within"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
            Text(seller.formattedDistance)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
