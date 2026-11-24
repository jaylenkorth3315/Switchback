import Foundation
import SwiftData

/// Test-only: populates the store with representative data when launched
/// with --seed, including a dangling Activity.route reference and
/// duplicate summits. Used to reproduce migration/maintenance issues.
@MainActor
enum DebugSeeder {
    static var isSeeding: Bool {
        #if DEBUG
        CommandLine.arguments.contains("--seed")
        #else
        false
        #endif
    }

    static func seed(in context: ModelContext) {
        try? context.delete(model: Summit.self)
        try? context.delete(model: Activity.self)
        try? context.delete(model: Route.self)

        var track: [TrackPoint] = []
        for i in 0..<6000 {
            track.append(TrackPoint(
                latitude: 39.58 + Double(i) * 0.00001,
                longitude: -105.70 + Double(i) * 0.000008,
                elevation: 3500 + Double(i) * 0.13,
                timestamp: Date(timeIntervalSince1970: 1_750_000_000 + Double(i) * 5)
            ))
        }

        let keeper = Route(name: "Keeper Route", track: track)
        let doomed = Route(name: "Doomed Route", track: track)
        context.insert(keeper)
        context.insert(doomed)

        let first = Activity(name: "Hike One", startDate: .now, route: keeper)
        first.endDate = .now
        first.track = track
        let second = Activity(name: "Hike Two", startDate: .now, route: doomed)
        second.endDate = .now
        second.track = track
        context.insert(first)
        context.insert(second)

        for _ in 0..<3 {
            context.insert(Summit(
                name: "Mount Bierstadt",
                elevationMeters: 4287,
                region: "Clear Creek County, Colorado",
                dateReached: Date(timeIntervalSince1970: 1_750_000_000),
                latitude: 39.5826,
                longitude: -105.6687,
                activity: first
            ))
        }
        try? context.save()

        context.delete(doomed)
        try? context.save()
        print("SEEDED with dangling route reference and duplicate summits")
    }
}
