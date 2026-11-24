import MapKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// The primary application experience. Currently renders with MapKit;
/// the Mapbox SDK replaces this layer once the access token is configured
/// (see README — UI stays SwiftUI either way).
struct MapTabView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var routes: [Route]

    /// Don't show summit markers when zoomed out past this span — they
    /// would carpet the map and bury the user's routes.
    private static let summitVisibilityMaxSpan: Double = 2.5

    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.5501, longitude: -105.7821),
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        ))
    )
    @State private var showingImporter = false
    @State private var importError: String?
    @State private var pendingImport: GPXParseResult?
    @State private var pendingImportName = ""
    @State private var visibleSummits: [SummitRecord] = []
    @State private var selectedSummit: SummitRecord?

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(visibleSummits) { summit in
                Annotation(summit.name, coordinate: summit.coordinate) {
                    Button {
                        selectedSummit = summit
                    } label: {
                        Image(systemName: "mountain.2.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Color.brandPrimary, in: Circle())
                    }
                }
            }
            ForEach(routes.filter { !$0.track.isEmpty }) { route in
                // Cartographic casing: a white halo under the accent line keeps
                // the route readable over dark terrain and satellite imagery.
                MapPolyline(coordinates: route.track.map(\.coordinate))
                    .stroke(.white, lineWidth: 6)
                MapPolyline(coordinates: route.track.map(\.coordinate))
                    .stroke(Color.routeAccent, lineWidth: 3.5)
                ForEach(route.waypoints) { waypoint in
                    Marker(waypoint.name, systemImage: "flag.fill", coordinate: waypoint.coordinate)
                        .tint(Color.brandNavy)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            updateVisibleSummits(for: context.region)
        }
        .sheet(item: $selectedSummit) { summit in
            SummitDetailView(summit: summit)
        }
        .onChange(of: appState.mapFocus) { _, focus in
            guard let focus else { return }
            cameraPosition = .region(MKCoordinateRegion(
                center: focus.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingImporter = true
            } label: {
                Label("Import GPX", systemImage: "square.and.arrow.down")
                    .padding(10)
            }
            .glassEffect()
            .padding()
            .padding(.bottom, 40)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .xml],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .confirmationDialog(
            "This GPX has recording timestamps",
            isPresented: .init(
                get: { pendingImport != nil },
                set: { if !$0 { pendingImport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Import as Route") {
                if let pendingImport {
                    importAsRoute(pendingImport, name: pendingImportName)
                }
                pendingImport = nil
            }
            Button("Import as Completed Activity") {
                if let pendingImport {
                    importAsActivity(pendingImport, name: pendingImportName)
                }
                pendingImport = nil
            }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            Text("It looks like a recorded activity from another app. Import it as a completed activity, or as a route to navigate.")
        }
        .alert("Import Failed", isPresented: .init(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
        .task {
            locationService.requestPermission()
            locationService.startUpdating()
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let parsed = try GPXParser.parse(fileURL: url)
            let name = parsed.name ?? url.deletingPathExtension().lastPathComponent
            if parsed.track.looksLikeRecordedActivity {
                // Timestamped tracks are usually finished activities exported
                // from another app — let the user decide which one this is.
                pendingImportName = name
                pendingImport = parsed
            } else {
                importAsRoute(parsed, name: name)
            }
        } catch {
            importError = "Could not read that GPX file. (\(error.localizedDescription))"
        }
    }

    private func importAsRoute(_ parsed: GPXParseResult, name: String) {
        // GPX imports default to private routes the user fully owns.
        let route = Route(
            name: name,
            routeType: .personal,
            track: parsed.track,
            waypoints: parsed.waypoints
        )
        modelContext.insert(route)
        zoomTo(parsed)
    }

    private func importAsActivity(_ parsed: GPXParseResult, name: String) {
        // The uploaded track becomes a route too, so it can be renamed,
        // downloaded, and navigated like any other route.
        let route = Route(
            name: name,
            routeType: .personal,
            track: parsed.track,
            waypoints: parsed.waypoints
        )
        modelContext.insert(route)

        let timestamps = parsed.track.compactMap(\.timestamp)
        let activity = Activity(name: name, startDate: timestamps.first ?? .now, route: route)
        activity.endDate = timestamps.last ?? activity.startDate
        activity.track = parsed.track
        activity.distanceMeters = parsed.track.totalDistanceMeters
        activity.elevationGainMeters = parsed.track.totalElevationGainMeters
        activity.elevationLossMeters = parsed.track.totalElevationLossMeters
        modelContext.insert(activity)

        SummitDetector.detectAndInsert(for: activity, in: modelContext)
        zoomTo(parsed)
    }

    private func updateVisibleSummits(for region: MKCoordinateRegion) {
        guard region.span.latitudeDelta <= Self.summitVisibilityMaxSpan else {
            visibleSummits = []
            return
        }
        let halfLat = region.span.latitudeDelta / 2
        let halfLon = region.span.longitudeDelta / 2
        visibleSummits = SummitDatabase.shared.summits(
            minLatitude: region.center.latitude - halfLat,
            maxLatitude: region.center.latitude + halfLat,
            minLongitude: region.center.longitude - halfLon,
            maxLongitude: region.center.longitude + halfLon,
            limit: 60
        )
    }

    private func zoomTo(_ parsed: GPXParseResult) {
        guard let first = parsed.track.first else { return }
        cameraPosition = .region(MKCoordinateRegion(
            center: first.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
}

#Preview {
    MapTabView()
        .environment(LocationService())
        .environment(AppState())
        .modelContainer(for: [Route.self, Activity.self, Summit.self], inMemory: true)
}
