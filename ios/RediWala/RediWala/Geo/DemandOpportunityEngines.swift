import Foundation

// MARK: - Demand Intelligence (foundation — no ML yet)

struct NeighborhoodDemandSnapshot: Equatable {
    var neighborhoodId: String
    var popularCategories: [String]
    var peakTimeWindows: [String]
    var activeVendorCount: Int
    var supplyGaps: [String]
    var estimatedDemandScore: Double
    var opportunityScore: Double
    var signals: [DemandSignal]
}

struct DemandSignal: Identifiable, Equatable {
    let id: String
    var category: String
    var intensity: Double
    var preferredWindow: String?
    var note: String
}

/// Computes neighborhood demand signals from local supply/economy hints.
@MainActor
enum DemandIntelligenceEngine {
    static func snapshot(
        for neighborhood: NeighborhoodDefinition,
        liveVendorCategories: [String],
        activeVendorCount: Int
    ) -> NeighborhoodDemandSnapshot {
        let suggested = Set(neighborhood.suggestedCategories)
        let live = Set(liveVendorCategories)
        let gaps = suggested.subtracting(live).sorted()

        let signals: [DemandSignal] = neighborhood.suggestedCategories.enumerated().map { index, category in
            let intensity = live.contains(category) ? 0.45 : 0.8
            return DemandSignal(
                id: "\(neighborhood.id)_\(category)",
                category: category,
                intensity: intensity,
                preferredWindow: peakWindows(for: category).first,
                note: live.contains(category) ? "Active supply present" : "Supply gap"
            )
        }

        let gapRatio = neighborhood.suggestedCategories.isEmpty
            ? 0
            : Double(gaps.count) / Double(neighborhood.suggestedCategories.count)
        let capacityPressure = min(1, Double(activeVendorCount) / Double(max(1, neighborhood.vendorCapacity)))
        let demandScore = min(1, 0.35 + gapRatio * 0.45 + (1 - capacityPressure) * 0.2)
        let opportunityScore = min(1, gapRatio * 0.7 + (1 - capacityPressure) * 0.3)

        return NeighborhoodDemandSnapshot(
            neighborhoodId: neighborhood.id,
            popularCategories: Array(neighborhood.suggestedCategories.prefix(5)),
            peakTimeWindows: ["6:00–9:00", "11:00–13:00", "17:00–20:00"],
            activeVendorCount: activeVendorCount,
            supplyGaps: gaps,
            estimatedDemandScore: demandScore,
            opportunityScore: opportunityScore,
            signals: signals
        )
    }

    private static func peakWindows(for category: String) -> [String] {
        switch category {
        case "milk", "flowers": return ["5:30–8:30"]
        case "fish", "breakfast", "bakery": return ["6:00–10:00"]
        case "vegetables": return ["7:00–11:00", "16:00–19:00"]
        case "kulfi", "roasted_corn", "food_truck": return ["16:00–21:00"]
        case "ironing", "laundry", "cable_bill": return ["9:00–13:00", "16:00–19:00"]
        default: return ["9:00–12:00"]
        }
    }
}

// MARK: - Opportunity Engine (placeholder architecture)

struct OpportunityInsight: Identifiable, Equatable {
    let id: String
    var title: String
    var detail: String
    var category: String?
    var score: Double
    var neighborhoodId: String
}

protocol OpportunityEngineProtocol {
    func evaluate(snapshot: NeighborhoodDemandSnapshot) -> [OpportunityInsight]
}

/// Rule-based placeholder. Future: ML demand forecasting + resource allocation.
struct OpportunityEngine: OpportunityEngineProtocol {
    func evaluate(snapshot: NeighborhoodDemandSnapshot) -> [OpportunityInsight] {
        var insights: [OpportunityInsight] = []

        for gap in snapshot.supplyGaps.prefix(4) {
            insights.append(
                OpportunityInsight(
                    id: "gap_\(snapshot.neighborhoodId)_\(gap)",
                    title: "Neighborhood needs more \(gap.replacingOccurrences(of: "_", with: " "))",
                    detail: "High demand category with low nearby supply.",
                    category: gap,
                    score: snapshot.opportunityScore,
                    neighborhoodId: snapshot.neighborhoodId
                )
            )
        }

        if snapshot.activeVendorCount == 0 {
            insights.append(
                OpportunityInsight(
                    id: "empty_\(snapshot.neighborhoodId)",
                    title: "No active vendors right now",
                    detail: "Customers may be waiting — strong window to go live.",
                    category: nil,
                    score: 0.9,
                    neighborhoodId: snapshot.neighborhoodId
                )
            )
        }

        return insights.sorted { $0.score > $1.score }
    }
}

// MARK: - Future AI extension points (TODO interfaces)

/// TODO: Neighborhood health scoring (retention, reliability, coverage).
protocol NeighborhoodHealthEngine {
    func healthScore(neighborhoodId: String) async -> Double
}

/// TODO: Demand forecasting across peak windows and festivals.
protocol DemandForecastingEngine {
    func forecast(neighborhoodId: String, horizonHours: Int) async -> [DemandSignal]
}

/// TODO: Route optimization across stops + demand clusters.
protocol RouteOptimizationEngine {
    func optimizeRoute(stopCoordinates: [(Double, Double)], demandWeights: [Double]) async -> [Int]
}

/// TODO: Vendor recommendations for customers (needs + distance + reliability).
protocol VendorRecommendationEngine {
    func recommend(scope: GeoQueryScope, needCategories: [String]) async -> [String]
}

/// TODO: Customer prediction (likely needs / visit timing).
protocol CustomerPredictionEngine {
    func predictNeeds(customerId: String, neighborhoodId: String) async -> [String]
}

/// TODO: Neighborhood growth / expansion planning.
protocol NeighborhoodGrowthEngine {
    func growthOpportunities(cityId: String) async -> [OpportunityInsight]
}

/// TODO: Resource allocation across vendors / stops / inventory.
protocol ResourceAllocationEngine {
    func allocate(demand: NeighborhoodDemandSnapshot, availableVendorIds: [String]) async -> [String: Double]
}
