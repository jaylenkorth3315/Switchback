import CoreLocation
import Observation

/// Wraps CLLocationManager for the map (when-in-use) and activity
/// recording (background updates while an activity is live).
@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var currentLocation: CLLocation?

    /// Set during an active recording so the owner can accumulate track points.
    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// Background updates keep the GPS track alive with the screen off.
    func beginRecordingUpdates() {
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func endRecordingUpdates() {
        manager.allowsBackgroundLocationUpdates = false
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations where location.horizontalAccuracy >= 0 {
                self.currentLocation = location
                self.onLocationUpdate?(location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Transient GPS errors are expected in canyons and under tree cover;
        // keep the last known fix rather than clearing state.
    }
}
