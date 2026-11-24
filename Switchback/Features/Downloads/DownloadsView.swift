import SwiftData
import SwiftUI

/// Offline management. Downloads and completed activities are kept in
/// separate sections by design — never mixed.
struct DownloadsView: View {
    @Query(filter: #Predicate<Route> { $0.isDownloaded }, sort: \Route.name)
    private var downloadedRoutes: [Route]

    @Query(sort: \Activity.startDate, order: .reverse)
    private var activities: [Activity]

    @Environment(RecordingSession.self) private var session
    @Environment(\.modelContext) private var modelContext

    private var completedActivities: [Activity] {
        activities.filter { $0.endDate != nil }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Downloaded Routes") {
                    if downloadedRoutes.isEmpty {
                        Text("Routes you download for offline use appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(downloadedRoutes) { route in
                            NavigationLink(value: route.persistentModelID) {
                                RouteRow(route: route)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    if session.activeRoute === route {
                                        session.activeRoute = nil
                                    }
                                    StoreMaintenance.prepareRouteForDeletion(route, in: modelContext)
                                    modelContext.delete(route)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    route.isDownloaded = false
                                } label: {
                                    Label("Remove Download", systemImage: "xmark.circle")
                                }
                            }
                        }
                    }
                }

                Section("Active Route") {
                    if let route = session.activeRoute {
                        NavigationLink(value: route.persistentModelID) {
                            RouteRow(route: route)
                        }
                    } else {
                        Text("No route in progress.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Completed Activities") {
                    if completedActivities.isEmpty {
                        Text("Finished activities appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(completedActivities) { activity in
                            NavigationLink(value: activity.persistentModelID) {
                                ActivityRow(activity: activity)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(activity)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                let model = modelContext.model(for: id)
                if let route = model as? Route {
                    RouteDetailView(route: route)
                } else if let activity = model as? Activity {
                    ActivityDetailView(activity: activity)
                }
            }
        }
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.name)
                .font(.headline)
            HStack(spacing: 12) {
                Text(activity.startDate, style: .date)
                Label(Format.distance(activity.distanceMeters), systemImage: "arrow.left.and.right")
                Label(Format.duration(activity.duration), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let location = LocationService()
    DownloadsView()
        .environment(RecordingSession(locationService: location))
        .modelContainer(for: [Route.self, Activity.self, Summit.self], inMemory: true)
}
