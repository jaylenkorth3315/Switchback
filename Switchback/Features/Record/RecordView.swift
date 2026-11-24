import SwiftData
import SwiftUI

/// Activity tracking center: start, pause, resume, end.
struct RecordView: View {
    @Environment(RecordingSession.self) private var session
    @Environment(\.modelContext) private var modelContext

    // Ticks the elapsed-time display once a second while recording.
    @State private var now = Date.now
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                elapsedTime
                metricsGrid
                Spacer()
                controls
            }
            .padding()
            .navigationTitle("Record")
            .onReceive(clock) { now = $0 }
        }
    }

    private var elapsedTime: some View {
        VStack(spacing: 4) {
            Text(Format.duration(session.elapsed))
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(stateLabel)
                .font(.subheadline)
                .foregroundStyle(session.state == .recording ? Color.routeAccent : Color.secondary)
        }
    }

    private var stateLabel: String {
        switch session.state {
        case .idle: "Ready"
        case .recording: "Recording"
        case .paused: "Paused"
        }
    }

    private var metricsGrid: some View {
        Grid(horizontalSpacing: 24, verticalSpacing: 24) {
            GridRow {
                metric("Distance", Format.distance(session.distanceMeters))
                metric("Pace", Format.pace(secondsPerKilometer: pace))
            }
            GridRow {
                metric("Gain", "+\(Format.elevation(session.elevationGainMeters))")
                metric("Elevation", session.currentElevationMeters.map(Format.elevation) ?? "--")
            }
        }
    }

    private var pace: Double? {
        guard session.distanceMeters > 0 else { return nil }
        return session.elapsed / (session.distanceMeters / 1000)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            switch session.state {
            case .idle:
                Button {
                    session.start()
                } label: {
                    Label("Start Activity", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color.routeAccentText)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .tint(Color.routeAccent)
            case .recording:
                Button {
                    session.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                endButton
            case .paused:
                Button {
                    session.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color.routeAccentText)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .tint(Color.routeAccent)
                endButton
            }
        }
    }

    private var endButton: some View {
        Button(role: .destructive) {
            if let activity = session.end() {
                modelContext.insert(activity)
                SummitDetector.detectAndInsert(for: activity, in: modelContext)
            }
        } label: {
            Label("End", systemImage: "stop.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(.red)
    }
}

#Preview {
    let location = LocationService()
    RecordView()
        .environment(location)
        .environment(RecordingSession(locationService: location))
        .modelContainer(for: [Route.self, Activity.self, Summit.self], inMemory: true)
}
