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
    private let geo = GeoContext.shared
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: SellerRepository,
        neighborhood: PilotNeighborhood = .westMambalam
    ) {
        self.repository = repository
        self.selectedNeighborhood = neighborhood
        self.cameraPosition = geo.cameraPosition
        geo.objectWillChange
            .sink { [weak self] _ in
                guard let self else { return }
                self.cameraPosition = self.geo.cameraPosition
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var selectedSeller: Seller? {
        sellers.first { $0.id == selectedSellerID }
    }

    func load(recenterIfNeeded: Bool = false) async {
        let scope = geo.queryScope()
        sellers = await repository.fetchNearbySellers(
            near: selectedNeighborhood,
            scope: scope
        )
        if recenterIfNeeded || !hasCenteredOnce {
            recenter()
            hasCenteredOnce = true
        }
    }

    func selectNeighborhood(_ neighborhood: PilotNeighborhood, recenter: Bool = false) {
        let changed = selectedNeighborhood != neighborhood
        selectedNeighborhood = neighborhood
        geo.selectPilotNeighborhood(neighborhood, recenter: recenter)
        Task { await load(recenterIfNeeded: recenter && changed) }
        if recenter {
            self.recenter()
            hasCenteredOnce = true
        }
    }

    func recenter() {
        geo.returnToNeighborhood()
        cameraPosition = geo.cameraPosition
    }

    func focus(on seller: Seller) {
        selectedSellerID = seller.id
        geo.zoomToVendor(latitude: seller.latitude, longitude: seller.longitude)
        cameraPosition = geo.cameraPosition
    }

    func selectSeller(_ id: String?) {
        selectedSellerID = id
    }

    static func region(for neighborhood: PilotNeighborhood) -> MKCoordinateRegion {
        let id = FirebaseIDMap.firebaseID(for: neighborhood)
        if let definition = NeighborhoodCatalog.neighborhood(id: id) {
            return definition.mapRegion
        }
        return MKCoordinateRegion(
            center: neighborhood.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: neighborhood.spanDelta,
                longitudeDelta: neighborhood.spanDelta
            )
        )
    }
}
