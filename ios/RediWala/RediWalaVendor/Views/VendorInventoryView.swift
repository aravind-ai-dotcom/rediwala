import SwiftUI

struct VendorInventoryView: View {
    @StateObject private var viewModel = VendorInventoryViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                SectionHeader(
                    titleKey: "inventory.title",
                    subtitleKey: "inventory.subtitle"
                )

                HStack(spacing: 12) {
                    SummaryCard(
                        titleKey: "inventory.in_stock",
                        value: "\(viewModel.inStockCount)",
                        systemImage: "checkmark.circle.fill",
                        tint: AppTheme.primary
                    )
                    SummaryCard(
                        titleKey: "inventory.total_items",
                        value: "\(viewModel.items.count)",
                        systemImage: "basket.fill",
                        tint: AppTheme.accent
                    )
                }

                ForEach(viewModel.items) { item in
                    inventoryRow(item)
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func inventoryRow(_ item: VendorInventoryItem) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(item.nameKey))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 8) {
                    Text("₹\(item.priceRupees)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                    Text("·")
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(LocalizedStringKey(item.unitKey))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer(minLength: 0)

            Button {
                viewModel.toggleStock(for: item)
            } label: {
                Text(LocalizedStringKey(item.inStock ? "inventory.mark_out" : "inventory.mark_in"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.inStock ? AppTheme.danger : AppTheme.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minWidth: 88, minHeight: 44)
                    .background((item.inStock ? AppTheme.danger : AppTheme.primary).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(LocalizedStringKey(item.inStock ? "inventory.mark_out" : "inventory.mark_in"))
            )
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VendorInventoryView()
        .environment(\.locale, Locale(identifier: "en"))
}
