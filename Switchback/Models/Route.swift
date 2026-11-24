import Foundation
import SwiftData

/// Visibility/origin of a route. Private is the default for GPX imports.
enum RouteType: String, Codable, CaseIterable, Sendable {
    case official
    case community
    case personal = "private"

    var displayName: String {
        switch self {
        case .official: "Official"
        case .community: "Community"
        case .personal: "Private"
        }
    }
}

/// Routes are first-class objects: geometry, waypoints, and difficulty
/// metadata bundled together, downloadable for offline navigation.
@Model
final class Route {
    var name: String
    var routeDescription: String
    var routeTypeRaw: String
    var track: [TrackPoint]
    var waypoints: [Waypoint]
    var distanceMeters: Double
    var elevationGainMeters: Double
    var highestPointMeters: Double?
    var region: String?
    var isDownloaded: Bool
    var createdAt: Date

    // Deliberately NO inverse relationship to Activity.route: with an
    // inverse, any touch of a dangling reference asserts inside SwiftData.
    // Integrity is enforced by StoreMaintenance.prepareRouteForDeletion
    // (call before every route delete) plus the launch repair pass.

    var routeType: RouteType {
        get { RouteType(rawValue: routeTypeRaw) ?? .personal }
        set { routeTypeRaw = newValue.rawValue }
    }

    init(
        name: String,
        routeDescription: String = "",
        routeType: RouteType = .personal,
        track: [TrackPoint] = [],
        waypoints: [Waypoint] = [],
        region: String? = nil,
        isDownloaded: Bool = false,
        createdAt: Date = .now
    ) {
        self.name = name
        self.routeDescription = routeDescription
        self.routeTypeRaw = routeType.rawValue
        self.track = track
        self.waypoints = waypoints
        self.distanceMeters = track.totalDistanceMeters
        self.elevationGainMeters = track.totalElevationGainMeters
        self.highestPointMeters = track.highestElevationMeters
        self.region = region
        self.isDownloaded = isDownloaded
        self.createdAt = createdAt
    }

    /// Recompute derived stats after the track changes (e.g. re-import).
    func refreshDerivedStats() {
        distanceMeters = track.totalDistanceMeters
        elevationGainMeters = track.totalElevationGainMeters
        highestPointMeters = track.highestElevationMeters
    }
}
