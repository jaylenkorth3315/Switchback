import Charts
import CoreLocation
import MapKit
import SwiftUI

struct ElevationPoint: Hashable {
    let distance: Double
    let elevation: Double
}

struct RouteDetailView: View {
    @Bindable var route: Route
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(RecordingSession.self) private var session
    @State private var isRenaming = false
    @State private var draftName = ""
    @State private var confirmingDelete = false
    // Computed once per route — walking the full track in body is what
    // made this screen slow to open on long routes.
    @State private var elevationProfile: [ElevationPoint] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapPreview
                statsGrid
                if !elevationProfile.isEmpty {
                    elevationChart
                }
                if !route.routeDescription.isEmpty {
                    Text(route.routeDescription)
                        .font(.body)
                }
                Toggle("Available Offline", isOn: $route.isDownloaded)
                if !route.waypoints.isEmpty {
                    waypointList
                }
            }
            .padding()
        }
        .navigationTitle(route.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: route.persistentModelID) {
            elevationProfile = Self.buildProfile(from: route.track)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Rename") {
                        draftName = route.name
                        isRenaming = true
                    }
                    if route.isDownloaded {
                        Button("Remove Download") {
                            route.isDownloaded = false
                        }
                    }
                    Button("Delete Route", role: .destructive) {
                        confirmingDelete = true
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .alert("Rename Route", isPresented: $isRenaming) {
            TextField("Route name", text: $draftName)
            Button("Save") {
                let trimmed = draftName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { route.name = trimmed }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete this route?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Route", role: .destructive) {
                if session.activeRoute === route {
                    session.activeRoute = nil
                }
                StoreMaintenance.prepareRouteForDeletion(route, in: modelContext)
                modelContext.delete(route)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Activities recorded on this route are kept.")
        }
    }

    private var mapPreview: some View {
        Map(initialPosition: .automatic) {
            if !route.track.isEmpty {
                MapPolyline(coordinates: route.track.map(\.coordinate))
                    .stroke(.white, lineWidth: 6)
                MapPolyline(coordinates: route.track.map(\.coordinate))
                    .stroke(Color.routeAccent, lineWidth: 3.5)
            }
            ForEach(route.waypoints) { waypoint in
                Marker(waypoint.name, systemImage: "flag.fill", coordinate: waypoint.coordinate)
                    .tint(Color.brandNavy)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
    }

    private var statsGrid: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
                stat("Distance", Format.distance(route.distanceMeters))
                stat("Elevation Gain", "+\(Format.elevation(route.elevationGainMeters))")
            }
            GridRow {
                stat("Highest Point", route.highestPointMeters.map(Format.elevation) ?? "--")
                stat("Type", route.routeType.displayName)
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// (cumulative distance, elevation) pairs, downsampled for the chart.
    static func buildProfile(from track: [TrackPoint]) -> [ElevationPoint] {
        var points: [ElevationPoint] = []
        var cumulative = 0.0
        var previous: CLLocation?
        for point in track {
            let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
            if let previous { cumulative += location.distance(from: previous) }
            previous = location
            if let elevation = point.elevation {
                points.append(ElevationPoint(distance: cumulative, elevation: elevation))
            }
        }
        let step = max(1, points.count / 200)
        return points.enumerated()
            .filter { $0.offset % step == 0 }
            .map(\.element)
    }

    /// Y domain anchored just below the route's lowest elevation, so the
    /// chart shows the hike's actual relief instead of empty space down
    /// to sea level.
    private var elevationDomain: ClosedRange<Double> {
        let elevations = elevationProfile.map(\.elevation)
        guard let lowest = elevations.min(), let highest = elevations.max(), lowest < highest else {
            return 0...1
        }
        let headroom = (highest - lowest) * 0.05
        return (lowest - headroom)...(highest + headroom)
    }

    private var elevationChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Elevation Profile")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(elevationProfile, id: \.distance) { point in
                AreaMark(
                    x: .value("Distance", point.distance / 1000),
                    yStart: .value("Base", elevationDomain.lowerBound),
                    yEnd: .value("Elevation", point.elevation)
                )
                .foregroundStyle(Color.brandSage.opacity(0.4))
                LineMark(
                    x: .value("Distance", point.distance / 1000),
                    y: .value("Elevation", point.elevation)
                )
                .foregroundStyle(Color.brandPrimary)
            }
            .chartYScale(domain: elevationDomain)
            .frame(height: 140)
        }
    }

    private var waypointList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waypoints")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(route.waypoints) { waypoint in
                HStack(spacing: 10) {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brandNavy)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(waypoint.name)
                            .font(.subheadline)
                        if let elevation = waypoint.elevation {
                            Text(Format.elevation(elevation))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
