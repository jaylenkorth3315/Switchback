import CoreLocation
import Foundation
import SwiftData

/// Detects summit visits from a completed activity's GPS track, per the
/// PRD workflow: complete activity → analyze track → add to collection.
/// Users never mark summits manually.
enum SummitDetector {
    /// A track must pass within this distance of a summit to count.
    /// Generous enough for GPS drift on a summit block, tight enough
    /// that a trail traversing below a peak doesn't count.
    static let detectionRadiusMeters: Double = 150

    /// Returns new Summit records for every cataloged peak the activity's
    /// track visited, already linked to the activity. Skips summits the
    /// activity has previously been credited with.
    static func summits(in activity: Activity) -> [Summit] {
        guard !activity.track.isEmpty else { return [] }
        let candidates = SummitDatabase.shared.summits(
            nearTrack: activity.track,
            radiusMeters: detectionRadiusMeters
        )
        guard !candidates.isEmpty else { return [] }

        let alreadyCredited = Set(activity.summits.map(\.name))
        var detected: [Summit] = []

        for candidate in candidates where !alreadyCredited.contains(candidate.name) {
            let summitLocation = CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
            var closestPoint: TrackPoint?
            var closestDistance = Double.greatestFiniteMagnitude

            for point in activity.track {
                let distance = summitLocation.distance(
                    from: CLLocation(latitude: point.latitude, longitude: point.longitude)
                )
                if distance < closestDistance {
                    closestDistance = distance
                    closestPoint = point
                }
            }

            if closestDistance <= detectionRadiusMeters {
                // Left unlinked and uninserted; detectAndInsert decides
                // which ones actually enter the store.
                detected.append(Summit(
                    name: candidate.name,
                    elevationMeters: candidate.elevationMeters ?? closestPoint?.elevation ?? 0,
                    region: candidate.region.isEmpty ? nil : candidate.region,
                    dateReached: closestPoint?.timestamp ?? activity.endDate ?? activity.startDate,
                    latitude: candidate.latitude,
                    longitude: candidate.longitude,
                    activity: nil
                ))
            }
        }
        return detected
    }

    /// Detects summits and inserts only the ones that aren't already in
    /// the collection. Same peak on the same calendar day counts as one
    /// ascent, so re-importing the same outing can't double-credit.
    @MainActor
    static func detectAndInsert(for activity: Activity, in context: ModelContext) {
        let detected = summits(in: activity)
        guard !detected.isEmpty else { return }
        let existing = (try? context.fetch(FetchDescriptor<Summit>())) ?? []
        let calendar = Calendar.current
        for summit in detected {
            let isDuplicate = existing.contains {
                $0.name == summit.name
                    && calendar.isDate($0.dateReached, inSameDayAs: summit.dateReached)
            }
            guard !isDuplicate else { continue }
            context.insert(summit)
            summit.activity = activity
        }
    }

    /// One-time cleanup for stores that accumulated duplicates before
    /// insertion-time dedupe existed. Keeps the earliest record of each
    /// (peak, day) pair.
    @MainActor
    static func removeDuplicateSummits(in context: ModelContext) {
        let descriptor = FetchDescriptor<Summit>(sortBy: [SortDescriptor(\.dateReached)])
        guard let all = try? context.fetch(descriptor) else { return }
        let calendar = Calendar.current
        var seen = Set<String>()
        for summit in all {
            let day = calendar.startOfDay(for: summit.dateReached).timeIntervalSince1970
            let key = "\(summit.name)|\(day)"
            if seen.contains(key) {
                context.delete(summit)
            } else {
                seen.insert(key)
            }
        }
    }
}
