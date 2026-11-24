import CoreLocation
import Foundation

/// A single point along a route or recorded GPS track.
struct TrackPoint: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double
    var elevation: Double?
    var timestamp: Date?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double, elevation: Double? = nil, timestamp: Date? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timestamp = timestamp
    }

    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.elevation = location.verticalAccuracy >= 0 ? location.altitude : nil
        self.timestamp = location.timestamp
    }
}

extension [TrackPoint] {
    /// Total horizontal distance in meters.
    var totalDistanceMeters: Double {
        guard count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<count {
            let a = CLLocation(latitude: self[i - 1].latitude, longitude: self[i - 1].longitude)
            let b = CLLocation(latitude: self[i].latitude, longitude: self[i].longitude)
            total += b.distance(from: a)
        }
        return total
    }

    /// Cumulative elevation gain in meters, ignoring points without elevation.
    var totalElevationGainMeters: Double {
        let elevations = compactMap(\.elevation)
        guard elevations.count > 1 else { return 0 }
        var gain = 0.0
        for i in 1..<elevations.count {
            let delta = elevations[i] - elevations[i - 1]
            if delta > 0 { gain += delta }
        }
        return gain
    }

    /// Cumulative elevation loss in meters, ignoring points without elevation.
    var totalElevationLossMeters: Double {
        let elevations = compactMap(\.elevation)
        guard elevations.count > 1 else { return 0 }
        var loss = 0.0
        for i in 1..<elevations.count {
            let delta = elevations[i] - elevations[i - 1]
            if delta < 0 { loss -= delta }
        }
        return loss
    }

    var highestElevationMeters: Double? {
        compactMap(\.elevation).max()
    }

    /// True when the track carries real recording timestamps — the signal
    /// that a GPX file is a completed activity rather than a planned route.
    var looksLikeRecordedActivity: Bool {
        let timestamps = compactMap(\.timestamp)
        guard timestamps.count >= 2, let first = timestamps.first, let last = timestamps.last else {
            return false
        }
        return last > first
    }
}
