import SwiftData
import SwiftUI

@main
struct SwitchbackApp: App {
    @State private var locationService: LocationService
    @State private var recordingSession: RecordingSession
    @State private var appState = AppState()

    init() {
        let location = LocationService()
        _locationService = State(initialValue: location)
        _recordingSession = State(initialValue: RecordingSession(locationService: location))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(locationService)
                .environment(recordingSession)
                .environment(appState)
        }
        .modelContainer(for: [Route.self, Activity.self, Summit.self])
    }
}
