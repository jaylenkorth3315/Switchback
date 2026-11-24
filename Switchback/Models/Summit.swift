import Foundation
import SwiftData

/// A summit visit, detected automatically from a completed activity's
/// GPS track — users never mark summits by hand.
@Model
final class Summit {
    var name: String
    var elevationMeters: Double
    var region: String?
    var dateReached: Date
    var latitude: Double
    var longitude: Double
    var activity: Activity?

    init(
        name: String,
        elevationMeters: Double,
        region: String? = nil,
        dateReached: Date,
        latitude: Double,
        longitude: Double,
        activity: Activity? = nil
    ) {
        self.name = name
        self.elevationMeters = elevationMeters
        self.region = region
        self.dateReached = dateReached
        self.latitude = latitude
        self.longitude = longitude
        self.activity = activity
    }
}
