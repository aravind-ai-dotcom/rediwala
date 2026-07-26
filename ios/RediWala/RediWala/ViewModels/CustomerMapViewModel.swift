import Combine
import Foundation
import MapKit
import SwiftUI

@MainActor
final class CustomerMapViewModel: ObservableObject {
    @Published var selectedNeighborhood: PilotNeighborhood
    @Published var sellers: [Seller] = []
    @Published var selectedSellerID: String?
    @Published var cameraPosition: MapCameraPosition

    private let repository: SellerRepository

    init(
        repository: SellerRepository,
        neighborhood: PilotNeighborhood = .tNagar
    ) {
        self.repository = repository
        self.selectedNeighborhood = neighborhood
        self.cameraPosition = .region(Self.region(for: neighborhood))
    }

    var selectedSeller: Seller? {
        sellers.first { $0.id == selectedSellerID }
    }

    func load() async {
        sellers = await repository.fetchNearbySellers()
        recenter()
    }

    func selectNeighborhood(_ neighborhood: PilotNeighborhood) {
        selectedNeighborhood = neighborhood
        recenter()
    }

    func recenter() {
        cameraPosition = .region(Self.region(for: selectedNeighborhood))
    }

    func selectSeller(_ id: String?) {
        selectedSellerID = id
    }

    func isFavorite(_ id: String) -> Bool {
        repository.isFavorite(id: id)
    }

    func toggleFavorite(_ id: String) {
        Task {
            await repository.toggleFavorite(id: id)
            objectWillChange.send()
        }
    }

    static func region(for neighborhood: PilotNeighborhood) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: neighborhood.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: neighborhood.spanDelta,
                longitudeDelta: neighborhood.spanDelta
            )
        )
    }
}
