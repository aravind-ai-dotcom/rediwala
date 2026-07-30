import Combine
import FirebaseDatabase
import Foundation

#if DEBUG
/// Development-only controller for deterministic demo scenarios. Not compiled into Release.
@MainActor
final class DemoScenarioController: ObservableObject {
    static let shared = DemoScenarioController()

    @Published var lastMessage: String = ""
    @Published var isBusy = false

    private var root: DatabaseReference {
        FirebaseDatabaseConfig.root
    }

    func resetAllScenarios() async {
        await run("Reset all demo scenarios") {
            try await self.applyMuruganLive()
            try await self.applyLakshmiExpired()
            try await self.applySivaPresence(expiringSoon: true)
            try await self.applyBabuStop(forcedIndex: 2)
            try await self.applyKumarEnded()
            try await self.applyClearRequests()
        }
    }

    func makeMuruganLive() async {
        await run("Murugan Live") { try await self.applyMuruganLive() }
    }

    func advanceMuruganWaypoint() async {
        await run("Advance Murugan") {
            let stops = [
                ("Postal Colony 1st Street", 13.0389, 80.2202),
                ("Postal Colony 2nd Street", 13.0382, 80.2211),
                ("Lake View Road", 13.0374, 80.2226),
                ("Arya Gowda Road", 13.0368, 80.2238),
                ("Station Road", 13.0379, 80.2251),
            ]
            let statusSnap = try await self.root.child("vendor_status/murugan").getData()
            let current = (statusSnap.value as? [String: Any])?["currentStop"] as? String
            let index = max(0, stops.firstIndex(where: { $0.0 == current }).map { min($0 + 1, stops.count - 1) } ?? 0)
            let stop = stops[index]
            let next = index + 1 < stops.count ? stops[index + 1].0 : nil
            try await self.writeLive(
                vendorId: "murugan",
                mode: "mobile",
                lat: stop.1,
                lng: stop.2,
                expiresInMinutes: 120,
                currentStop: stop.0,
                nextStop: next
            )
        }
    }

    func expireLakshmiFlowers() async {
        await run("Expire Lakshmi Flowers") { try await self.applyLakshmiExpired() }
    }

    func confirmSivaStillPresent() async {
        await run("Confirm Siva present") { try await self.applySivaPresence(expiringSoon: false) }
    }

    func advanceBabuApartmentStop() async {
        await run("Advance Babu") { try await self.applyBabuStop(forcedIndex: nil) }
    }

    func startKumarRound() async {
        await run("Start Kumar round") {
            try await self.writeLive(
                vendorId: "kumar_cable",
                mode: "scheduled",
                lat: 13.0379,
                lng: 80.2251,
                expiresInMinutes: 180,
                currentStop: "Station Road",
                nextStop: "Postal Colony"
            )
        }
    }

    func endKumarRound() async {
        await run("End Kumar round") { try await self.applyKumarEnded() }
    }

    func clearCustomerRequests() async {
        await run("Clear customer requests") { try await self.applyClearRequests() }
    }

    func restoreDefaultNeeds() {
        CustomerNeedsStore.shared.replaceToday(with: [.vegetables, .flowers, .ironing])
        lastMessage = "Restored default Today’s Needs"
    }

    private func run(_ label: String, _ work: () async throws -> Void) async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await work()
            lastMessage = "OK: \(label)"
        } catch {
            lastMessage = "Failed: \(label) — \(error.localizedDescription)"
        }
    }

    private func applyMuruganLive() async throws {
        try await writeLive(
            vendorId: "murugan",
            mode: "mobile",
            lat: 13.0386,
            lng: 80.2208,
            expiresInMinutes: 120,
            currentStop: "Postal Colony 1st Street",
            nextStop: "Postal Colony 2nd Street"
        )
    }

    private func applyLakshmiExpired() async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        try await root.child("vendor_status/lakshmi").setValue([
            "vendorId": "lakshmi",
            "isLive": false,
            "serviceMode": "stationary",
            "lastSeen": now,
            "availabilityTextEn": "Offline",
            "presenceExpiresAt": now,
            "isPresenceConfirmationRequired": true,
        ] as [String: Any])
    }

    private func applySivaPresence(expiringSoon: Bool) async throws {
        try await writeLive(
            vendorId: "siva_ironing",
            mode: "stationary",
            lat: 12.9862,
            lng: 80.2588,
            expiresInMinutes: expiringSoon ? 10 : 60,
            currentStop: nil,
            nextStop: nil,
            confirmationRequired: true
        )
    }

    private func applyBabuStop(forcedIndex: Int?) async throws {
        let stops = [
            ("Kurinji Enclave, Block A", 12.9844, 80.2572),
            ("Kurinji Enclave, Block B", 12.9841, 80.2579),
            ("Seashore Apartments, Tower C", 12.9838, 80.2601),
            ("Seashore Apartments, Tower A", 12.9836, 80.2604),
            ("Kannappa Residency", 12.9860, 80.2585),
        ]
        let statusSnap = try await root.child("vendor_status/babu_laundry").getData()
        let current = (statusSnap.value as? [String: Any])?["currentStop"] as? String
        let index: Int
        if let forcedIndex {
            index = min(max(forcedIndex, 0), stops.count - 1)
        } else {
            index = max(0, stops.firstIndex(where: { $0.0 == current }).map { min($0 + 1, stops.count - 1) } ?? 2)
        }
        let stop = stops[index]
        let next = index + 1 < stops.count ? stops[index + 1].0 : nil
        try await writeLive(
            vendorId: "babu_laundry",
            mode: "mobile",
            lat: stop.1,
            lng: stop.2,
            expiresInMinutes: 120,
            currentStop: stop.0,
            nextStop: next
        )
    }

    private func applyKumarEnded() async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        try await root.child("vendor_status/kumar_cable").setValue([
            "vendorId": "kumar_cable",
            "isLive": false,
            "serviceMode": "scheduled",
            "lastSeen": now,
            "availabilityTextEn": "Expected soon",
            "isPresenceConfirmationRequired": true,
        ] as [String: Any])
    }

    private func applyClearRequests() async throws {
        try await root.child("customerRequests").removeValue()
        try await root.child("customer_interest").removeValue()
    }

    private func writeLive(
        vendorId: String,
        mode: String,
        lat: Double,
        lng: Double,
        expiresInMinutes: Int,
        currentStop: String?,
        nextStop: String?,
        confirmationRequired: Bool = false
    ) async throws {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let nowIso = formatter.string(from: now)
        let expiresIso = formatter.string(from: now.addingTimeInterval(Double(expiresInMinutes) * 60))
        var status: [String: Any] = [
            "vendorId": vendorId,
            "sellerId": vendorId,
            "isLive": true,
            "serviceMode": mode,
            "lastSeen": nowIso,
            "startedAt": nowIso,
            "availabilityTextEn": "Live nearby",
            "isPresenceConfirmationRequired": confirmationRequired,
            "presenceConfirmedAt": nowIso,
            "presenceExpiresAt": expiresIso,
            "presenceCheckIntervalMinutes": confirmationRequired ? 60 : 120,
            "lastLocationUpdateAt": nowIso,
        ]
        if let currentStop { status["currentStop"] = currentStop }
        if let nextStop { status["nextStop"] = nextStop }
        try await root.child("vendor_status/\(vendorId)").setValue(status)
        try await root.child("vendor_locations/\(vendorId)").setValue([
            "vendorId": vendorId,
            "latitude": lat,
            "longitude": lng,
            "updatedAt": nowIso,
        ] as [String: Any])
    }
}
#endif
