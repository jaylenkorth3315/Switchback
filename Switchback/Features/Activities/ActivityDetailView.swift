import MapKit
import SwiftUI

struct ActivityDetailView: View {
    @Bindable var activity: Activity
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isRenaming = false
    @State private var draftName = ""
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !activity.track.isEmpty {
                    mapPreview
                }
                statsGrid
                if !activity.summits.isEmpty {
                    summitsSection
                }
                if let route = activity.route {
                    LabeledContent("Route", value: route.name)
                }
            }
            .padding()
        }
        .navigationTitle(activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Rename") {
                        draftName = activity.name
                        isRenaming = true
                    }
                    Button("Delete Activity", role: .destructive) {
                        confirmingDelete = true
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .alert("Rename Activity", isPresented: $isRenaming) {
            TextField("Activity name", text: $draftName)
            Button("Save") {
                let trimmed = draftName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { activity.name = trimmed }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete this activity?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Activity", role: .destructive) {
                modelContext.delete(activity)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Summits earned from this activity stay in your collection.")
        }
    }

    private var mapPreview: some View {
        Map(initialPosition: .automatic) {
            MapPolyline(coordinates: activity.track.map(\.coordinate))
                .stroke(.white, lineWidth: 6)
            MapPolyline(coordinates: activity.track.map(\.coordinate))
                .stroke(Color.routeAccent, lineWidth: 3.5)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
    }

    private var statsGrid: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
                stat("Date", activity.startDate.formatted(date: .abbreviated, time: .shortened))
                stat("Duration", Format.duration(activity.duration))
            }
            GridRow {
                stat("Distance", Format.distance(activity.distanceMeters))
                stat("Pace", Format.pace(secondsPerKilometer: activity.paceSecondsPerKilometer))
            }
            GridRow {
                stat("Elevation Gain", "+\(Format.elevation(activity.elevationGainMeters))")
                stat("Elevation Loss", "-\(Format.elevation(activity.elevationLossMeters))")
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

    private var summitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summits Reached")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(activity.summits) { summit in
                HStack(spacing: 10) {
                    Image(systemName: "mountain.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(summit.name)
                            .font(.subheadline)
                        Text("\(Format.elevation(summit.elevationMeters)) · \(summit.region ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
