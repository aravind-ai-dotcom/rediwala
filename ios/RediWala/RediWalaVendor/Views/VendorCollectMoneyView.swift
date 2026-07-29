import SwiftUI

/// Collect money via GPay/UPI and log today's sales — simple tally, not full accounting.
struct VendorCollectMoneyView: View {
    let vendorID: String
    let vendorName: String
    let businessName: String
    let onSaleRecorded: (VendorPaymentRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var notes = ""
    @State private var showAmountQR = false

    private var upiPayload: VendorUPIQRPayload {
        VendorUPIQRPayload(
            upiID: VendorPaymentSettings.upiID,
            payeeName: VendorPaymentSettings.payeeName,
            amountRupees: nil,
            note: nil
        )
    }

    private var amountPayload: VendorUPIQRPayload? {
        guard let amount = Int(amountText.filter(\.isNumber)), amount > 0 else { return nil }
        return VendorUPIQRPayload(
            upiID: VendorPaymentSettings.upiID,
            payeeName: VendorPaymentSettings.payeeName,
            amountRupees: amount,
            note: notes.isEmpty ? nil : notes
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    gpayHeader

                    if showAmountQR, let payload = amountPayload, let qr = VendorQRGenerator.upiImage(for: payload) {
                        amountQRSection(payload: payload, image: qr)
                    } else {
                        staticQRSection
                    }

                    recordSaleSection
                    todayTallyHint
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("money.collect.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                }
            }
        }
    }

    private var gpayHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color(red: 0.0, green: 0.45, blue: 0.36))
                Text("money.gpay.title")
                    .font(.title2.weight(.heavy))
            }
            Text(VendorPaymentSettings.upiID)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Text("money.gpay.hint")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var staticQRSection: some View {
        VStack(spacing: 12) {
            if let qr = VendorQRGenerator.upiImage(for: upiPayload) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(red: 0.0, green: 0.45, blue: 0.36).opacity(0.3), lineWidth: 2)
                    }
            }
            Text("money.scan.gpay")
                .font(.headline.weight(.bold))
        }
    }

    private func amountQRSection(payload: VendorUPIQRPayload, image: UIImage) -> some View {
        VStack(spacing: 12) {
            Text("₹\(payload.amountRupees ?? 0)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.0, green: 0.45, blue: 0.36))
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Button("money.show.open_qr") {
                showAmountQR = false
            }
            .font(.caption)
        }
    }

    private var recordSaleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("money.record.title")
                .font(.headline.weight(.bold))

            TextField("money.record.amount", text: $amountText)
                .keyboardType(.numberPad)
                .font(.title.weight(.bold))
                .padding(12)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            TextField("money.record.note", text: $notes)
                .padding(12)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 10) {
                Button {
                    showAmountQR = true
                } label: {
                    Label("money.show.qr", systemImage: "qrcode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(amountPayload == nil)

                Button {
                    recordSale()
                } label: {
                    Text("money.record.save")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.0, green: 0.45, blue: 0.36))
                .disabled((Int(amountText.filter(\.isNumber)) ?? 0) <= 0)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var todayTallyHint: some View {
        let total = VendorBillingStore.todayTotal(vendorID: vendorID)
        let count = VendorBillingStore.todayCustomerCount(vendorID: vendorID)
        return VStack(spacing: 4) {
            Text("money.today.total")
                .font(.subheadline.weight(.semibold))
            Text("₹\(total)")
                .font(.title.weight(.heavy))
                .foregroundStyle(AppTheme.primary)
            Text(String(format: String(localized: "money.today.count"), count))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(AppTheme.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func recordSale() {
        guard let amount = Int(amountText.filter(\.isNumber)), amount > 0 else { return }
        let record = VendorPaymentRecord(
            id: UUID().uuidString,
            vendorID: vendorID,
            vendorName: vendorName,
            businessName: businessName,
            amountRupees: amount,
            notes: notes.isEmpty ? nil : notes,
            createdAt: Date(),
            isCompleted: true
        )
        VendorBillingStore.save(record)
        onSaleRecorded(record)
        amountText = ""
        notes = ""
        showAmountQR = false
    }
}
