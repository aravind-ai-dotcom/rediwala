import MapKit
import SwiftUI

struct VendorDetailView: View {
    let vendorID: String
    @EnvironmentObject private var favorites: FavoritesViewModel
    @ObservedObject private var followStore = CustomerVendorFollowStore.shared
    @State private var seller: Seller?
    @State private var isLoading = true
    @State private var interestMessage: String?
    @State private var isSubmittingInterest = false

    var body: some View {
        Group {
            if let seller {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(for: seller)
                        followActions(for: seller)

                        if seller.hasAnnouncement || seller.todaysMessagePreview != nil {
                            todaysMessageSection(for: seller)
                        }

                        aboutCard(for: seller)
                        infoRows(for: seller)
                        progressCard(for: seller)
                        myDaySection(for: seller)
                        interestSection(for: seller)
                        mapPreview(for: seller)
                        detailActions(for: seller)
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
            CustomerRecentlyViewedStore.shared.record(vendorID: vendorID)
            if favorites.isFavorite(vendorID) {
                CustomerRelationshipStore.shared.recordInteraction(vendorID: vendorID)
            }
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
                remoteURL: seller.photoURL,
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

    private func followActions(for seller: Seller) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    if followStore.isFollowing(seller.id) {
                        followStore.unfollow(seller.id)
                    } else {
                        followStore.track(seller.id)
                    }
                } label: {
                    Label {
                        Text(followStore.isFollowing(seller.id) ? "vendor.unfollow" : "vendor.follow")
                    } icon: {
                        Image(systemName: followStore.isFollowing(seller.id) ? "person.badge.minus" : "person.badge.plus")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .accessibilityLabel(Text(followStore.isFollowing(seller.id) ? "vendor.unfollow" : "vendor.follow"))

                Button {
                    followStore.isTracked(seller.id)
                        ? followStore.follow(seller.id)
                        : followStore.track(seller.id)
                } label: {
                    Label {
                        Text(followStore.isTracked(seller.id) ? "vendor.untrack" : "vendor.track")
                    } icon: {
                        Image(systemName: followStore.isTracked(seller.id) ? "location.slash.fill" : "location.fill")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(Text(followStore.isTracked(seller.id) ? "vendor.untrack" : "vendor.track"))
            }

            HStack(spacing: 10) {
                Button {
                    followStore.isMuted(seller.id) ? followStore.track(seller.id) : followStore.mute(seller.id)
                } label: {
                    Label {
                        Text(followStore.isMuted(seller.id) ? "vendor.unmute" : "vendor.mute")
                    } icon: {
                        Image(systemName: followStore.isMuted(seller.id) ? "speaker.wave.2.fill" : "speaker.slash")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)

                Button {
                    followStore.hide(seller.id)
                } label: {
                    Label {
                        Text("vendor.hide")
                    } icon: {
                        Image(systemName: "eye.slash")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)

                ShareLink(
                    item: "\(seller.name) · RediWala — \(String(localized: String.LocalizationValue(seller.category.localizationKey))) near \(String(localized: String.LocalizationValue(seller.neighborhood.nameKey)))"
                ) {
                    Label {
                        Text("vendor.share")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func todaysMessageSection(for seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "home.todays_message", subtitleKey: "home.todays_message.subtitle")
            if seller.hasAnnouncement {
                AnnouncementPlayerView(
                    sellerName: seller.name,
                    durationSeconds: seller.announcementDurationSeconds,
                    storagePath: seller.announcementStoragePath
                )
            } else if let preview = seller.todaysMessagePreview {
                Text(preview)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func progressCard(for seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("vendorDetail.progress")
                .font(.title3.weight(.bold))
            if let progress = seller.progressLabel {
                Text(progress)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }
            if let eta = seller.etaLabel {
                Text(eta)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(LocalizedStringKey(seller.serviceMode.titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            if let apartment = seller.apartmentComplex {
                Text(apartment)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private func interestSection(for seller: Seller) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "home.my_interests", subtitleKey: "home.my_interests.subtitle")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(CustomerInterestService.RequestType.allCases) { type in
                    Button {
                        submitInterest(type: type, seller: seller)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: icon(for: type))
                                .font(.title3)
                            Text(LocalizedStringKey(type.titleKey))
                                .font(.caption.weight(.semibold))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .padding(8)
                        .background(AppTheme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmittingInterest)
                }
            }

            if let interestMessage {
                Text(interestMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }

    private func icon(for type: CustomerInterestService.RequestType) -> String {
        switch type {
        case .interested: return "hand.thumbsup.fill"
        case .comeToMyArea: return "mappin.and.ellipse"
        case .needToday: return "leaf.fill"
        case .needProduct: return "cart.fill"
        case .comeThisEvening: return "moon.stars.fill"
        }
    }

    private func submitInterest(type: CustomerInterestService.RequestType, seller: Seller) {
        guard let customerID = CustomerIdentityStore.loadUID() else {
            interestMessage = String(localized: "interest.error.not_signed_in")
            return
        }
        isSubmittingInterest = true
        Task {
            do {
                try await CustomerInterestService.submit(
                    customerID: customerID,
                    vendorCategory: FirebaseIDMap.firebaseID(for: seller.category),
                    neighborhood: seller.neighborhood,
                    type: type,
                    productHint: seller.category == .vegetables ? "Fresh vegetables" : nil,
                    preferredTime: type == .comeThisEvening ? "6 PM – 8 PM" : nil
                )
                interestMessage = String(localized: "interest.success")
            } catch {
                interestMessage = String(localized: "interest.error.generic")
            }
            isSubmittingInterest = false
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

    private func detailActions(for seller: Seller) -> some View {
        HStack(spacing: 12) {
            Button {
                openInMaps(seller)
            } label: {
                Label {
                    Text("vendor.open_map")
                } icon: {
                    Image(systemName: "map.fill")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("vendor.open_map"))

            if let url = URL(string: "tel:\(seller.phone.filter(\.isNumber))") {
                Link(destination: url) {
                    Label {
                        Text("seller.call")
                    } icon: {
                        Image(systemName: "phone.fill")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel(Text("seller.call"))
            }
        }
    }

    private func openInMaps(_ seller: Seller) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: seller.coordinate))
        item.name = seller.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

#Preview("English") {
    let repo = FirebaseSellerRepository()
    return NavigationStack {
        VendorDetailView(vendorID: "murugan")
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Tamil Dark") {
    let repo = FirebaseSellerRepository()
    return NavigationStack {
        VendorDetailView(vendorID: "lakshmi")
    }
    .environmentObject(FavoritesViewModel(repository: repo))
    .preferredColorScheme(.dark)
    .environment(\.locale, Locale(identifier: "ta"))
}
