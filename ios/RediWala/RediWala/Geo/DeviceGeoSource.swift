import Combine
import CoreLocation
import Foundation

/// Device GPS is ingested ONLY here, then published into GeoContext.
/// Feature code must never create CLLocationManager itself.
@MainActor
final class DeviceGeoSource: NSObject, ObservableObject {
    static let shared = DeviceGeoSource()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastCoordinate: CLLocationCoordinate2D?
    @Published private(set) var lastError: String?

    private let manager = CLLocationManager()
    private var isRunning = false

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func startIfNeeded(for mode: GeoLocationMode) {
        guard mode == .liveGPS || mode == .hybrid else {
            stop()
            return
        }
        #if targetEnvironment(simulator)
        // Simulator / airplane resilience: keep Demo-quality coordinates via GeoContext neighborhood.
        lastError = nil
        GeoContext.shared.ingestDeviceCoordinate(nil)
        return
        #else
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            beginUpdates()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            lastError = "Location permission denied. Staying on neighborhood context."
            GeoContext.shared.ingestDeviceCoordinate(nil)
        @unknown default:
            GeoContext.shared.ingestDeviceCoordinate(nil)
        }
        #endif
    }

    func stop() {
        guard isRunning else { return }
        manager.stopUpdatingLocation()
        isRunning = false
    }

    private func beginUpdates() {
        guard !isRunning else { return }
        isRunning = true
        manager.startUpdatingLocation()
    }
}

extension DeviceGeoSource: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            startIfNeeded(for: GeoContext.shared.mode)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            lastCoordinate = location.coordinate
            lastError = nil
            GeoContext.shared.ingestDeviceCoordinate(location.coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error.localizedDescription
            // Fail soft — GeoContext keeps neighborhood coordinate.
            GeoContext.shared.ingestDeviceCoordinate(nil)
        }
    }
}
