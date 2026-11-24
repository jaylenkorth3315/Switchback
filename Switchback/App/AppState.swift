import CoreLocation
import Observation

enum AppTab: Hashable {
    case explore, map, record, downloads, profile
}

/// A one-shot request to center the Map tab somewhere. The requestID
/// makes repeated focuses on the same coordinate still trigger onChange.
struct MapFocusTarget: Equatable {
    let latitude: Double
    let longitude: Double
    let requestID: UUID

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Cross-tab navigation state, injected app-wide.
@Observable
@MainActor
final class AppState {
    var selectedTab: AppTab = .explore
    var mapFocus: MapFocusTarget?

    /// Switch to the Map tab centered on a coordinate.
    func focusMap(on coordinate: CLLocationCoordinate2D) {
        mapFocus = MapFocusTarget(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            requestID: UUID()
        )
        selectedTab = .map
    }
}
