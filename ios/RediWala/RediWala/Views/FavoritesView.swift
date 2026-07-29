import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesViewModel: FavoritesViewModel
    @State private var favorites: [Seller] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading && favorites.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if favorites.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("favorites.empty.title")
                    } icon: {
                        Image(systemName: "heart")
                    }
                } description: {
                    Text("favorites.empty.subtitle")
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(favorites) { seller in
                            ZStack(alignment: .topTrailing) {
                                NavigationLink {
                                    VendorDetailView(vendorID: seller.id)
                                } label: {
                                    SellerCard(
                                        seller: seller,
                                        isFavorite: true,
                                        showsFavoriteButton: false,
                                        onFavoriteToggle: {}
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    favoritesViewModel.toggle(seller.id)
                                } label: {
                                    Image(systemName: "heart.fill")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(AppTheme.danger)
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.borderless)
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                                .accessibilityLabel(Text("vendorDetail.removeFavorite"))
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("tab.favorites"))
        .navigationBarTitleDisplayMode(.large)
        .task(id: favoritesViewModel.favoriteIDs) {
            isLoading = true
            favorites = await favoritesViewModel.fetchFavorites()
            isLoading = false
        }
    }
}

#Preview {
    let repo = FirebaseSellerRepository()
    return NavigationStack {
        FavoritesView()
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .environment(\.locale, Locale(identifier: "en"))
}
