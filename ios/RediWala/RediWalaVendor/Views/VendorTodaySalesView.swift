import SwiftUI

/// Simple list of today's sales for end-of-day reconciliation.
struct VendorTodaySalesView: View {
    let vendorID: String
    @Environment(\.dismiss) private var dismiss
    @State private var sales: [VendorPaymentRecord] = []
    @State private var manualTotalText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("money.reconcile.title")
                            .font(.headline.weight(.bold))
                        HStack {
                            Text("money.reconcile.app_total")
                            Spacer()
                            Text("₹\(appTotal)")
                                .font(.title3.weight(.heavy))
                        }
                        HStack {
                            TextField("money.reconcile.your_total", text: $manualTotalText)
                                .keyboardType(.numberPad)
                            if let manual = Int(manualTotalText.filter(\.isNumber)), manual != appTotal {
                                Text(manual > appTotal ? "money.reconcile.more" : "money.reconcile.less")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }

                Section("money.today.sales") {
                    if sales.isEmpty {
                        Text("money.today.empty")
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        ForEach(sales) { sale in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("₹\(sale.amountRupees)")
                                        .font(.headline.weight(.bold))
                                    if let note = sale.notes {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                Spacer()
                                Text(Self.timeFormatter.string(from: sale.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("money.today.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                }
            }
            .onAppear {
                sales = VendorBillingStore.load(vendorID: vendorID)
                    .filter { Calendar.current.isDateInToday($0.createdAt) && $0.isCompleted }
            }
        }
    }

    private var appTotal: Int {
        sales.map(\.amountRupees).reduce(0, +)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
