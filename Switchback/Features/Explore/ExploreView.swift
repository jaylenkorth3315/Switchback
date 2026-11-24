import SwiftData
import SwiftUI

/// Route and summit discovery. Information-focused: filters on distance,
/// gain, and region — never popularity-based sorting.
struct ExploreView: View {
    @Query(sort: \Route.name) private var routes: [Route]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var routeTypeFilter: RouteType?

    private var filteredRoutes: [Route] {
        routes.filter { route in
            let matchesSearch = searchText.isEmpty
                || route.name.localizedStandardContains(searchText)
                || (route.region?.localizedStandardContains(searchText) ?? false)
            let matchesType = routeTypeFilter == nil || route.routeType == routeTypeFilter
            return matchesSearch && matchesType
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes Yet",
                        systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                        description: Text("Import a GPX file from the Map tab to add your first route.")
                    )
                } else {
                    List(filteredRoutes) { route in
                        NavigationLink(value: route.persistentModelID) {
                            RouteRow(route: route)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Explore")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                // Models must not ride through navigation values directly —
                // the path's snapshot can outlive them and crash on access.
                if let route = modelContext.model(for: id) as? Route {
                    RouteDetailView(route: route)
                }
            }
            .searchable(text: $searchText, prompt: "Routes, trails, summits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Route Type", selection: $routeTypeFilter) {
                            Text("All").tag(RouteType?.none)
                            ForEach(RouteType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(RouteType?.some(type))
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease")
                    }
                }
            }
        }
    }
}

struct RouteRow: View {
    let route: Route

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(route.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 14) {
                    metric("arrow.left.and.right", Format.distance(route.distanceMeters))
                    metric("arrow.up.right", "+\(Format.elevation(route.elevationGainMeters))")
                    if let highest = route.highestPointMeters {
                        metric("mountain.2", Format.elevation(highest))
                    }
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                Text(route.routeType.displayName)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.brandSky, in: Capsule())
                    .foregroundStyle(Color.brandNavy)
                if route.isDownloaded {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func metric(_ icon: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .monospacedDigit()
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    ExploreView()
        .modelContainer(for: [Route.self, Activity.self, Summit.self], inMemory: true)
}
