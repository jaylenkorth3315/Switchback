import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            Tab("Explore", systemImage: "binoculars", value: AppTab.explore) {
                ExploreView()
            }
            Tab("Map", systemImage: "map", value: AppTab.map) {
                MapTabView()
            }
            Tab("Record", systemImage: "record.circle", value: AppTab.record) {
                RecordView()
            }
            Tab("Downloads", systemImage: "arrow.down.circle", value: AppTab.downloads) {
                DownloadsView()
            }
            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                ProfileView()
            }
        }
        .task {
            if DebugSeeder.isSeeding {
                DebugSeeder.seed(in: modelContext)
                return
            }
            StoreMaintenance.run(in: modelContext)
        }
    }
}

#Preview {
    RootView()
        .environment(LocationService())
        .environment(AppState())
}
