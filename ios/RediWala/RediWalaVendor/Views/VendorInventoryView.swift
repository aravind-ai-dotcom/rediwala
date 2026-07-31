import SwiftUI

struct VendorInventoryView: View {
    @StateObject private var viewModel: VendorInventoryViewModel
    var onDone: (() -> Void)?
    private let category: VendorCategory

    init(category: VendorCategory = .vegetables, onDone: (() -> Void)? = nil) {
        self.category = category
        self.onDone = onDone
        _viewModel = StateObject(wrappedValue: VendorInventoryViewModel(category: category))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedText.resolve("offerings.title", fallback: "Today's Offerings"))
                    .font(.largeTitle.weight(.bold))
                Text(category.offeringsTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    compactStat(
                        title: "Ready",
                        value: "\(viewModel.items.filter(\.availableToday).count)",
                        tint: AppTheme.primary
                    )
                    compactStat(
                        title: "Listed",
                        value: "\(viewModel.items.count)",
                        tint: AppTheme.accent
                    )
                }

                ForEach($viewModel.items) { $item in
                    offeringRow($item)
                }
                .onChange(of: viewModel.items) { _, _ in
                    viewModel.persist()
                }

                if viewModel.items.isEmpty {
                    Text("No offerings for \(category.englishTitle) yet.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, 8)
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar {
            if let onDone {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.persist()
                        onDone()
                    }
                }
            }
        }
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

    private func offeringRow(_ item: Binding<VendorInventoryItem>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.wrappedValue.displayName)
                        .font(.headline.weight(.bold))
                    Text(item.wrappedValue.rateCardLabel)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                    if let notes = item.wrappedValue.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()
                Button {
                    viewModel.toggleStock(for: item.wrappedValue)
                } label: {
                    Text(item.wrappedValue.availableToday ? "Today" : "Off")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.wrappedValue.availableToday ? AppTheme.primary : AppTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background((item.wrappedValue.availableToday ? AppTheme.primary : AppTheme.textSecondary).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Stepper(
                    "₹\(item.wrappedValue.priceRupees)",
                    value: item.priceRupees,
                    in: 5...2000,
                    step: 5
                )
                .font(.caption.weight(.semibold))

                if item.wrappedValue.kind == .product {
                    Stepper(
                        "Stock \(item.wrappedValue.stockQuantity ?? 0)",
                        value: Binding(
                            get: { item.wrappedValue.stockQuantity ?? 0 },
                            set: { item.wrappedValue.stockQuantity = $0 }
                        ),
                        in: 0...500,
                        step: 1
                    )
                    .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    VendorInventoryView()
}
