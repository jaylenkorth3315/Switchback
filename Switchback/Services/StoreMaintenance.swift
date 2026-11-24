import Foundation
import SwiftData

/// One-shot launch repairs for the user's store. Each pass must be cheap
/// and idempotent — this runs on every app start.
@MainActor
enum StoreMaintenance {
    static func run(in context: ModelContext) {
        repairDanglingRouteReferences(in: context)
        SummitDetector.removeDuplicateSummits(in: context)
    }

    /// Detaches every activity referencing a route, then it's safe to
    /// delete. Must be called before any `context.delete(route)` — the
    /// relationship is unidirectional, so SwiftData won't do this for us.
    static func prepareRouteForDeletion(_ route: Route, in context: ModelContext) {
        guard let activities = try? context.fetch(FetchDescriptor<Activity>()) else { return }
        let routeID = route.persistentModelID
        for activity in activities where activity.route?.persistentModelID == routeID {
            activity.route = nil
        }
    }

    /// Clears Activity.route references that point at deleted routes
    /// (left behind by builds that deleted routes without detaching).
    /// Only persistentModelID is read on the faulted object — safe.
    static func repairDanglingRouteReferences(in context: ModelContext) {
        guard let activities = try? context.fetch(FetchDescriptor<Activity>()),
              let routes = try? context.fetch(FetchDescriptor<Route>()) else {
            return
        }
        let validRouteIDs = Set(routes.map(\.persistentModelID))
        for activity in activities {
            guard let route = activity.route else { continue }
            if !validRouteIDs.contains(route.persistentModelID) {
                activity.route = nil
            }
        }
    }
}
