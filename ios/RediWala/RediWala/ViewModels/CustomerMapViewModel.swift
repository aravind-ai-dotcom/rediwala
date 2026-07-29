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
    @Published private(set) var hasCenteredOnce = false

    private let repository: SellerRepository

    init(
        repository: SellerRepository,
        neighborhood: PilotNeighborhood = .westMambalam
    ) {
        self.repository = repository
        self.selectedNeighborhood = neighborhood
        self.cameraPosition = .region(Self.region(for: neighborhood))
    }

    var selectedSeller: Seller? {
        sellers.first { $0.id == selectedSellerID }
    }

    func load(recenterIfNeeded: Bool = false) async {
        sellers = await repository.fetchNearbySellers(near: selectedNeighborhood)
        if recenterIfNeeded || !hasCenteredOnce {
            recenter()
            hasCenteredOnce = true
        }
    }

    func selectNeighborhood(_ neighborhood: PilotNeighborhood, recenter: Bool = false) {
        let changed = selectedNeighborhood != neighborhood
        selectedNeighborhood = neighborhood
        Task { await load(recenterIfNeeded: recenter && changed) }
        if recenter {
            self.recenter()
            hasCenteredOnce = true
        }
    }

    func recenter() {
        cameraPosition = .region(Self.region(for: selectedNeighborhood))
    }

    func focus(on seller: Seller) {
        selectedSellerID = seller.id
        cameraPosition = .region(
            MKCoordinateRegion(
                center: seller.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        )
    }

    func selectSeller(_ id: String?) {
        selectedSellerID = id
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
