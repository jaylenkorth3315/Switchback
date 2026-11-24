import CoreLocation
import Foundation

/// A named point of interest along a route (junction, water source, summit, etc.).
struct Waypoint: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var note: String?
    var latitude: Double
    var longitude: Double
    var elevation: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        note: String? = nil,
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
}
