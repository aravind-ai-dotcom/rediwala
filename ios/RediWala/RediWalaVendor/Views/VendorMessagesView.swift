import SwiftUI

/// Vendor Messages tab — neighborhood customer requests, phrased as human messages.
struct VendorMessagesView: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel

    var body: some View {
        NavigationStack {
            List {
                if liveSession.customerRequests.filter({ $0.status == .open }).isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No messages yet")
                                .font(.headline.weight(.bold))
                            Text("When neighbors ask about tomatoes, jasmine, or a stop nearby — they’ll show up here.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section(LocalizedText.resolve("tab.messages", fallback: "Messages")) {
                        ForEach(liveSession.customerRequests.filter { $0.status == .open }) { request in
                            messageRow(request)
                        }
                    }
                }
            }
            .navigationTitle(LocalizedText.resolve("tab.messages", fallback: "Messages"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func messageRow(_ request: CustomerInterestRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(humanPrompt(for: request))
                    .font(.body.weight(.semibold))
                Spacer()
                Text(request.neighborhood.localizedName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let time = request.preferredTime {
                Text(time)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 8) {
                Button("I'll stop by") {
                    liveSession.acceptRequest(request.id)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)

                Button("Add to route") {
                    liveSession.addRequestToRoute(request)
                }
                .buttonStyle(.bordered)

                Button("Later", role: .destructive) {
                    liveSession.dismissRequest(request.id)
                }
                .buttonStyle(.bordered)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 4)
    }

    private func humanPrompt(for request: CustomerInterestRequest) -> String {
        if let product = request.productHint, !product.isEmpty {
            return "Do you have \(product.lowercased()) today?"
        }
        switch request.requestType {
        case .comeToMyArea:
            return "Can you stop by my apartment?"
        case .needToday:
            return "Need this today — are you nearby?"
        case .needProduct:
            return "How much for jasmine today?"
        case .comeThisEvening:
            return "Can you come this evening?"
        case .interested:
            return "I'm interested — I'll wait."
        }
    }
}
