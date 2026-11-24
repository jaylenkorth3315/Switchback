import CoreLocation
import MapKit
import SwiftData
import SwiftUI

/// Sheet wrapper used by the map's summit markers.
struct SummitDetailView: View {
    let summit: SummitRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SummitDetailContent(summit: summit)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// Information page for a mountain: its details, a mini map (tap to open
/// the full Map tab), and a table of the user's ascents. Pushable from
/// any NavigationStack, or presented via SummitDetailView.
struct SummitDetailContent: View {
    let summit: SummitRecord

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Summit.dateReached, order: .reverse) private var allSummitVisits: [Summit]

    /// Visits matched by name or proximity, so renamed peaks still count.
    private var ascents: [Summit] {
        allSummitVisits.filter { visit in
            if visit.name == summit.name { return true }
            let visitLocation = CLLocation(latitude: visit.latitude, longitude: visit.longitude)
            let summitLocation = CLLocation(latitude: summit.latitude, longitude: summit.longitude)
            return visitLocation.distance(from: summitLocation) < 300
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                miniMap
                ascentsTable
            }
            .padding()
        }
        .navigationTitle(summit.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let elevation = summit.elevationMeters {
                Text(Format.elevation(elevation))
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.brandPrimary)
            }
            if !summit.region.isEmpty {
                Text(summit.region)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !ascents.isEmpty {
                Label(
                    "Summited \(ascents.count) \(ascents.count == 1 ? "time" : "times")",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.brandPrimary)
            }
        }
    }

    private var miniMap: some View {
        Button {
            appState.focusMap(on: summit.coordinate)
            dismiss()
        } label: {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: summit.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            ))) {
                Marker(summit.name, systemImage: "mountain.2.fill", coordinate: summit.coordinate)
                    .tint(Color.brandPrimary)
            }
            .mapStyle(.standard(elevation: .realistic))
            .allowsHitTesting(false)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .bottomTrailing) {
                Label("Open in Map", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(10)
            }
        }
        .buttonStyle(.plain)
    }

    private var ascentsTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Ascents")
                .font(.caption)
                .foregroundStyle(.secondary)
            if ascents.isEmpty {
                Text("You haven't summited this peak yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Date")
                        Text("Activity")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    Divider()
                    ForEach(ascents) { ascent in
                        GridRow {
                            Text(ascent.dateReached, format: .dateTime.year().month().day())
                                .monospacedDigit()
                            Text(ascent.activity?.name ?? "—")
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}
