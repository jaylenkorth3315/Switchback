import Foundation

/// Shared display formatting so distance/elevation/pace read consistently
/// across Map, Record, Downloads, and Profile. MainActor-bound because
/// MeasurementFormatter is not thread-safe and all callers are views.
@MainActor
enum Format {
    private static let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    static func distance(_ meters: Double) -> String {
        distanceFormatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }

    static func elevation(_ meters: Double) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let usesMetric = Locale.current.measurementSystem == .metric
        let converted = usesMetric ? measurement : measurement.converted(to: .feet)
        return converted.formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                                numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    static func duration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func pace(secondsPerKilometer: Double?) -> String {
        guard let secondsPerKilometer, secondsPerKilometer.isFinite else { return "--" }
        let usesMetric = Locale.current.measurementSystem == .metric
        let perUnit = usesMetric ? secondsPerKilometer : secondsPerKilometer * 1.609344
        let unit = usesMetric ? "km" : "mi"
        let minutes = Int(perUnit) / 60
        let seconds = Int(perUnit) % 60
        return String(format: "%d:%02d /%@", minutes, seconds, unit)
    }
}
