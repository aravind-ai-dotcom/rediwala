import SwiftUI

struct CategoryVendorsView: View {
    let category: SellerCategory
    @EnvironmentObject private var favorites: FavoritesViewModel
    @State private var sellers: [Seller] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading && sellers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sellers.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("categoryVendors.empty.title")
                    } icon: {
                        Image(systemName: "storefront")
                    }
                } description: {
                    Text("categoryVendors.empty.subtitle")
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sellers) { seller in
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
                                }
                                .buttonStyle(.borderless)
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text(LocalizedStringKey(category.localizationKey)))
        .navigationBarTitleDisplayMode(.large)
        .task {
            isLoading = true
            sellers = await favorites.repository.fetchSellers(category: category)
            isLoading = false
        }
    }
}

#Preview {
    let repo = LocalSellerRepository()
    return NavigationStack {
        CategoryVendorsView(category: .vegetables)
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .environment(\.locale, Locale(identifier: "en"))
}
