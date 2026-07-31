import SwiftUI

/// Simple human neighborhood messages — task-oriented, not a chat platform clone.
struct CustomerMessagesView: View {
    private let threads: [(id: String, title: String, preview: String, eta: String)] = [
        ("1", "Murugan · Vegetables", "Do you have fresh tomatoes?", "About 10 minutes"),
        ("2", "Lakshmi · Flowers", "How much for jasmine today?", "28 min"),
        ("3", "Ravi · Laundry", "I'll wait near the gate.", "Tomorrow")
    ]

    var body: some View {
        List {
            Section {
                Text("Ask your neighborhood sellers. Keep it short and human.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .listRowBackground(Color.clear)
            }

            ForEach(threads, id: \.id) { thread in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "bubble.left.fill")
                                .foregroundStyle(AppTheme.primary)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(thread.title)
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text(thread.eta)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        Text(thread.preview)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(LocalizedText.resolve("tab.messages", fallback: "Messages"))
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CustomerWatchListView: View {
    @ObservedObject var viewModel: CustomerHomeViewModel

    var body: some View {
        List {
            Section {
                Text("Temporary · task-based. Waiting for payment, return visit, delivery, callback.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .listRowBackground(Color.clear)
            }

            if viewModel.watchList.isEmpty {
                ContentUnavailableView(
                    "Nobody on watch",
                    systemImage: "eye",
                    description: Text("Track a nearby seller from Home when you need a return visit or delivery.")
                )
            } else {
                ForEach(viewModel.watchList) { seller in
                    NavigationLink {
                        VendorDetailView(vendorID: seller.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(seller.name)
                                    .font(.headline.weight(.bold))
                                Text(seller.etaLabel ?? seller.formattedDistance)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            availabilityDot(for: seller)
                        }
                    }
                }
            }
        }
        .navigationTitle(LocalizedText.resolve("tab.watchlist", fallback: "Today's Watch"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func availabilityDot(for seller: Seller) -> some View {
        Circle()
            .fill(NeighborhoodAvailability.status(for: seller).color)
            .frame(width: 10, height: 10)
    }
}

enum NeighborhoodAvailability {
    case available
    case expectedSoon
    case nobodyNearby

    var color: Color {
        switch self {
        case .available: return AppTheme.primary
        case .expectedSoon: return AppTheme.accent
        case .nobodyNearby: return AppTheme.danger
        }
    }

    var label: String {
        switch self {
        case .available: return "Available"
        case .expectedSoon: return "Expected Soon"
        case .nobodyNearby: return "Nobody nearby"
        }
    }

    static func status(for seller: Seller) -> NeighborhoodAvailability {
        if seller.isEffectivelyLive { return .available }
        if seller.etaLabel != nil || seller.routeStops.contains(where: { $0.status == .upcoming }) {
            return .expectedSoon
        }
        return .nobodyNearby
    }

    static func overall(liveCount: Int, expectedCount: Int) -> NeighborhoodAvailability {
        if liveCount > 0 { return .available }
        if expectedCount > 0 { return .expectedSoon }
        return .nobodyNearby
    }
}
