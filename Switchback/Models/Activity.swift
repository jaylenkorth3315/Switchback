import Foundation
import SwiftData

/// A recorded outing: the primary recorded object in Switchback.
@Model
final class Activity {
    var name: String
    var startDate: Date
    var endDate: Date?
    var track: [TrackPoint]
    var distanceMeters: Double
    var elevationGainMeters: Double
    var elevationLossMeters: Double
    var averageHeartRate: Double?
    var weatherSummary: String?
    var route: Route?

    @Relationship(inverse: \Summit.activity)
    var summits: [Summit]

    var duration: TimeInterval {
        (endDate ?? .now).timeIntervalSince(startDate)
    }

    /// Average pace in seconds per kilometer, nil until there is distance.
    var paceSecondsPerKilometer: Double? {
        guard distanceMeters > 0 else { return nil }
        return duration / (distanceMeters / 1000)
    }

    init(
        name: String,
        startDate: Date = .now,
        route: Route? = nil
    ) {
        self.name = name
        self.startDate = startDate
        self.endDate = nil
        self.track = []
        self.distanceMeters = 0
        self.elevationGainMeters = 0
        self.elevationLossMeters = 0
        self.route = route
        self.summits = []
    }
}
