import SwiftUI

struct VendorInventoryView: View {
    @StateObject private var viewModel = VendorInventoryViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedText.resolve("offerings.title", fallback: "Today's Offerings"))
                    .font(.largeTitle.weight(.bold))
                Text(LocalizedText.resolve("offerings.subtitle", fallback: "Products and services available today"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    compactStat(
                        title: "Ready",
                        value: "\(viewModel.items.filter(\.availableToday).count)",
                        tint: AppTheme.primary
                    )
                    compactStat(
                        title: "Total",
                        value: "\(viewModel.items.count)",
                        tint: AppTheme.accent
                    )
                }

                ForEach(viewModel.items) { item in
                    offeringRow(item)
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func compactStat(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func offeringRow(_ item: VendorInventoryItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.displayName)
                        .font(.headline.weight(.bold))
                    Text(item.kind.title)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.info.opacity(0.12))
                        .foregroundStyle(AppTheme.info)
                        .clipShape(Capsule())
                }
                Text("₹\(item.priceRupees)/\(item.unitLabel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                if let minutes = item.serviceDurationMinutes {
                    Text("~\(minutes) min")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else if let stock = item.stockQuantity {
                    Text("Stock \(stock)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            Button {
                viewModel.toggleStock(for: item)
            } label: {
                Text(item.availableToday ? "Today" : "Off")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.availableToday ? AppTheme.primary : AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background((item.availableToday ? AppTheme.primary : AppTheme.textSecondary).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    VendorInventoryView()
}
