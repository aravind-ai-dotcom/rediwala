import SwiftUI

struct CustomerHomeView: View {
    @ObservedObject var viewModel: CustomerHomeViewModel
    @EnvironmentObject private var favorites: FavoritesViewModel

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        Group {
            if viewModel.browseMode == .map {
                CustomerMapView(
                    viewModel: viewModel.mapViewModel,
                    favorites: favorites,
                    onShowList: {
                        viewModel.browseMode = .list
                    }
                )
            } else {
                listContent
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("tab.home"))
        .navigationBarTitleDisplayMode(viewModel.browseMode == .map ? .inline : .large)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.browseMode) { _, mode in
            guard mode == .map else { return }
            viewModel.mapViewModel.selectNeighborhood(viewModel.selectedNeighborhood)
        }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                modePicker

                ForEach(viewModel.categoriesByGroup, id: \.group.id) { entry in
                    categorySection(group: entry.group, categories: entry.categories)
                }

                nearbySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(viewModel.greetingKey))
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(viewModel.selectedNeighborhood.nameKey))
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(LocalizedStringKey(viewModel.selectedNeighborhood.tamilNameKey))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Picker(selection: $viewModel.selectedNeighborhood) {
                ForEach(PilotNeighborhood.allCases) { neighborhood in
                    Text(LocalizedStringKey(neighborhood.nameKey)).tag(neighborhood)
                }
            } label: {
                Text("map.neighborhood")
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text("map.neighborhood"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(CustomerHomeViewModel.BrowseMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.browseMode = mode
                    }
                } label: {
                    Label {
                        Text(LocalizedStringKey(mode.titleKey))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } icon: {
                        Image(systemName: mode.systemImage)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(viewModel.browseMode == mode ? .white : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(viewModel.browseMode == mode ? AppTheme.primary : AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(viewModel.browseMode == mode ? [.isSelected] : [])
            }
        }
    }

    private func categorySection(group: CategoryGroup, categories: [MarketCategory]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: LocalizedStringKey(group.titleKey))

            LazyVGrid(columns: categoryColumns, spacing: 10) {
                ForEach(categories) { category in
                    if category.isComingSoon {
                        CategoryCard(
                            titleKey: LocalizedStringKey(category.localizationKey),
                            systemImage: category.systemImage,
                            tint: tint(for: group),
                            isComingSoon: true
                        )
                    } else {
                        NavigationLink {
                            CategoryVendorsView(category: category.category)
                        } label: {
                            CategoryCard(
                                titleKey: LocalizedStringKey(category.localizationKey),
                                systemImage: category.systemImage,
                                tint: tint(for: group)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "home.nearbyNow")

            if viewModel.isLoading && viewModel.sellers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.sellers) { seller in
                        sellerRow(seller)
                    }
                }
            }
        }
    }

    private func sellerRow(_ seller: Seller) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                VendorDetailView(vendorID: seller.id)
            } label: {
                SellerCard(
                    seller: seller,
                    isFavorite: favorites.isFavorite(seller.id),
                    showsFavoriteButton: false,
                    onFavoriteToggle: {}
                )
            }
            .buttonStyle(.plain)

            Button {
                favorites.toggle(seller.id)
            } label: {
                Image(systemName: favorites.isFavorite(seller.id) ? "heart.fill" : "heart")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(favorites.isFavorite(seller.id) ? AppTheme.danger : AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .padding(.top, 8)
            .padding(.trailing, 8)
            .accessibilityLabel(
                Text(favorites.isFavorite(seller.id) ? "vendorDetail.removeFavorite" : "vendorDetail.addFavorite")
            )
        }
    }

    private func tint(for group: CategoryGroup) -> Color {
        switch group.tint {
        case .accent: return AppTheme.accent
        case .info: return AppTheme.info
        case .primary: return AppTheme.primary
        }
    }
}

#Preview("English List") {
    let repo = LocalSellerRepository()
    return NavigationStack {
        CustomerHomeView(viewModel: CustomerHomeViewModel(repository: repo))
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Tamil") {
    let repo = LocalSellerRepository()
    return NavigationStack {
        CustomerHomeView(viewModel: CustomerHomeViewModel(repository: repo))
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .environment(\.locale, Locale(identifier: "ta"))
}

#Preview("Dark Small Phone") {
    let repo = LocalSellerRepository()
    return NavigationStack {
        CustomerHomeView(viewModel: CustomerHomeViewModel(repository: repo))
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .xLarge)
}
