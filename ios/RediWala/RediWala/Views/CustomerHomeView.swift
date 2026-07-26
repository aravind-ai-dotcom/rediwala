import SwiftUI

struct CustomerHomeView: View {
    @StateObject private var viewModel = CustomerHomeViewModel()

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                locationHeader

                Text("Categories")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                LazyVGrid(columns: categoryColumns, spacing: 12) {
                    ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { index, category in
                        CategoryCard(
                            title: category.title,
                            systemImage: category.systemImage,
                            tint: index.isMultiple(of: 2) ? AppTheme.primary : AppTheme.accent
                        )
                    }
                }

                Text("Nearby Vendors")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 4)

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.vendors) { vendor in
                        VendorCard(
                            name: vendor.name,
                            distance: vendor.distance,
                            category: vendor.category,
                            isOpen: vendor.isOpen
                        )
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var locationHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppTheme.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Current Location")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(viewModel.currentLocation)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CustomerHomeView()
}
