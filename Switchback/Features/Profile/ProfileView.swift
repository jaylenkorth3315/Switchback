import SwiftData
import SwiftUI

/// Personal outdoor history: activities, summit collection, statistics.
/// Deliberately minimal social functionality.
struct ProfileView: View {
    @Query(sort: \Activity.startDate, order: .reverse) private var activities: [Activity]
    @Query(sort: \Summit.dateReached, order: .reverse) private var summits: [Summit]
    @Environment(\.modelContext) private var modelContext

    private var completed: [Activity] {
        activities.filter { $0.endDate != nil }
    }

    private var totalDistance: Double {
        completed.reduce(0) { $0 + $1.distanceMeters }
    }

    private var totalGain: Double {
        completed.reduce(0) { $0 + $1.elevationGainMeters }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Statistics") {
                    LabeledContent("Activities", value: "\(completed.count)")
                    LabeledContent("Total Distance", value: Format.distance(totalDistance))
                    LabeledContent("Total Elevation Gain", value: Format.elevation(totalGain))
                    LabeledContent("Summits", value: "\(summits.count)")
                }

                Section("Summit Collection") {
                    if summits.isEmpty {
                        Text("Summits are detected automatically when you complete an activity.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(summits) { summit in
                            NavigationLink(value: summit.persistentModelID) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(summit.name)
                                        .font(.headline)
                                    HStack(spacing: 8) {
                                        Text(Format.elevation(summit.elevationMeters))
                                        Text(summit.dateReached, style: .date)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Recent Activities") {
                    if completed.isEmpty {
                        Text("Record your first activity from the Record tab.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(completed.prefix(10)) { activity in
                            NavigationLink(value: activity.persistentModelID) {
                                ActivityRow(activity: activity)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                let model = modelContext.model(for: id)
                if let visit = model as? Summit {
                    SummitDetailContent(summit: SummitDatabase.shared.record(matching: visit))
                } else if let activity = model as? Activity {
                    ActivityDetailView(activity: activity)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Route.self, Activity.self, Summit.self], inMemory: true)
}
