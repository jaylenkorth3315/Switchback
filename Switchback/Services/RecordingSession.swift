import CoreLocation
import Foundation
import Observation

/// Drives the Record tab: start → pause/resume → end, accumulating
/// distance, elevation gain/loss, and the GPS track as fixes arrive.
@Observable
@MainActor
final class RecordingSession {
    enum State {
        case idle
        case recording
        case paused
    }

    private(set) var state: State = .idle
    private(set) var track: [TrackPoint] = []
    private(set) var distanceMeters: Double = 0
    private(set) var elevationGainMeters: Double = 0
    private(set) var elevationLossMeters: Double = 0
    private(set) var startDate: Date?

    /// Route being navigated, if the activity started from one.
    var activeRoute: Route?

    private var accumulatedDuration: TimeInterval = 0
    private var segmentStart: Date?
    private var lastLocation: CLLocation?

    private let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    var elapsed: TimeInterval {
        var total = accumulatedDuration
        if let segmentStart {
            total += Date.now.timeIntervalSince(segmentStart)
        }
        return total
    }

    var currentElevationMeters: Double? {
        locationService.currentLocation.flatMap {
            $0.verticalAccuracy >= 0 ? $0.altitude : nil
        }
    }

    func start(route: Route? = nil) {
        guard state == .idle else { return }
        track = []
        distanceMeters = 0
        elevationGainMeters = 0
        elevationLossMeters = 0
        accumulatedDuration = 0
        lastLocation = nil
        activeRoute = route
        startDate = .now
        segmentStart = .now
        state = .recording
        locationService.onLocationUpdate = { [weak self] location in
            self?.consume(location)
        }
        locationService.beginRecordingUpdates()
    }

    func pause() {
        guard state == .recording else { return }
        accumulatedDuration = elapsed
        segmentStart = nil
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        segmentStart = .now
        state = .recording
    }

    /// Ends the session and returns a populated Activity for the caller
    /// to insert into the model context.
    func end() -> Activity? {
        guard state != .idle, let startDate else { return nil }
        locationService.onLocationUpdate = nil
        locationService.endRecordingUpdates()

        let activity = Activity(
            name: activeRoute?.name ?? Self.defaultActivityName(for: startDate),
            startDate: startDate,
            route: activeRoute
        )
        activity.endDate = .now
        activity.track = track
        activity.distanceMeters = distanceMeters
        activity.elevationGainMeters = elevationGainMeters
        activity.elevationLossMeters = elevationLossMeters

        state = .idle
        self.startDate = nil
        segmentStart = nil
        activeRoute = nil
        return activity
    }

    private func consume(_ location: CLLocation) {
        guard state == .recording else { return }
        // Reject noisy fixes so the track and stats stay honest.
        guard location.horizontalAccuracy <= 50 else { return }

        if let last = lastLocation {
            distanceMeters += location.distance(from: last)
            if location.verticalAccuracy >= 0, last.verticalAccuracy >= 0 {
                let delta = location.altitude - last.altitude
                if delta > 0 {
                    elevationGainMeters += delta
                } else {
                    elevationLossMeters -= delta
                }
            }
        }
        lastLocation = location
        track.append(TrackPoint(location: location))
    }

    private static func defaultActivityName(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let period = switch hour {
        case 0..<12: "Morning"
        case 12..<17: "Afternoon"
        default: "Evening"
        }
        return "\(period) Hike"
    }
}
