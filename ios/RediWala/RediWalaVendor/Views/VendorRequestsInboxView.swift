import SwiftUI

struct VendorRequestsInboxView: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sortMode: RequestSortMode = .urgency

    enum RequestSortMode: String, CaseIterable, Identifiable {
        case urgency
        case time
        case category

        var id: String { rawValue }

        var title: String {
            switch self {
            case .urgency: return "Urgency"
            case .time: return "Time"
            case .category: return "Category"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(RequestSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("business.requests.title") {
                    if sortedRequests.isEmpty {
                        ContentUnavailableView(
                            "business.requests.empty",
                            systemImage: "tray",
                            description: Text("business.requests.empty.subtitle")
                        )
                    } else {
                        ForEach(sortedRequests) { request in
                            requestRow(request)
                        }
                    }
                }
            }
            .navigationTitle("business.requests.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                }
            }
        }
    }

    private var sortedRequests: [CustomerInterestRequest] {
        let open = liveSession.customerRequests.filter { $0.status == .open }
        switch sortMode {
        case .urgency:
            return open.sorted { $0.urgencyScore > $1.urgencyScore }
        case .time:
            return open.sorted { $0.createdAt > $1.createdAt }
        case .category:
            return open.sorted { $0.vendorCategory < $1.vendorCategory }
        }
    }

    private func requestRow(_ request: CustomerInterestRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: request.requestType.systemImage)
                    .foregroundStyle(AppTheme.primary)
                Text(request.requestType.title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Text(LocalizedStringKey(request.neighborhood.labelKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let product = request.productHint, !product.isEmpty {
                Text(product)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let time = request.preferredTime {
                Label(time, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 8) {
                Button("business.requests.accept") {
                    liveSession.acceptRequest(request.id)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)

                Button("business.requests.add_route") {
                    liveSession.addRequestToRoute(request)
                }
                .buttonStyle(.bordered)

                Button("business.requests.dismiss", role: .destructive) {
                    liveSession.dismissRequest(request.id)
                }
                .buttonStyle(.bordered)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}
