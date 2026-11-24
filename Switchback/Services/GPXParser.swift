import Foundation

/// Parses GPX 1.0/1.1 files into track points and waypoints.
/// Handles exports from CalTopo, Gaia GPS, AllTrails, and Peakbagger,
/// which all emit standard <trk>/<trkpt> and <wpt> elements.
struct GPXParseResult {
    var name: String?
    var track: [TrackPoint]
    var waypoints: [Waypoint]
}

enum GPXParseError: Error {
    case unreadableFile
    case malformedXML
    case emptyTrack
}

final class GPXParser: NSObject, XMLParserDelegate {
    private var track: [TrackPoint] = []
    private var waypoints: [Waypoint] = []
    private var gpxName: String?

    private var currentElement = ""
    private var currentText = ""
    private var pendingLat: Double?
    private var pendingLon: Double?
    private var pendingElevation: Double?
    private var pendingTime: Date?
    private var pendingWaypointName: String?
    private var inWaypoint = false
    private var inTrackPoint = false
    private var inMetadataOrTrackHeader = false

    private let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // Strava, Garmin, and some watches emit fractional seconds.
    private let fractionalTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func parse(fileURL: URL) throws -> GPXParseResult {
        let needsSecurityScope = fileURL.startAccessingSecurityScopedResource()
        defer { if needsSecurityScope { fileURL.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: fileURL) else {
            throw GPXParseError.unreadableFile
        }
        return try parse(data: data)
    }

    static func parse(data: Data) throws -> GPXParseResult {
        let delegate = GPXParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else { throw GPXParseError.malformedXML }
        guard !delegate.track.isEmpty || !delegate.waypoints.isEmpty else {
            throw GPXParseError.emptyTrack
        }
        return GPXParseResult(
            name: delegate.gpxName,
            track: delegate.track,
            waypoints: delegate.waypoints
        )
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""
        switch elementName {
        case "trkpt", "rtept":
            inTrackPoint = true
            pendingLat = attributeDict["lat"].flatMap(Double.init)
            pendingLon = attributeDict["lon"].flatMap(Double.init)
            pendingElevation = nil
            pendingTime = nil
        case "wpt":
            inWaypoint = true
            pendingLat = attributeDict["lat"].flatMap(Double.init)
            pendingLon = attributeDict["lon"].flatMap(Double.init)
            pendingElevation = nil
            pendingWaypointName = nil
        case "metadata", "trk":
            inMetadataOrTrackHeader = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "ele":
            pendingElevation = Double(text)
        case "time" where inTrackPoint:
            pendingTime = timestampFormatter.date(from: text)
                ?? fractionalTimestampFormatter.date(from: text)
        case "name":
            if inWaypoint {
                pendingWaypointName = text
            } else if inMetadataOrTrackHeader, gpxName == nil, !text.isEmpty {
                gpxName = text
            }
        case "trkpt", "rtept":
            if let lat = pendingLat, let lon = pendingLon {
                track.append(TrackPoint(
                    latitude: lat,
                    longitude: lon,
                    elevation: pendingElevation,
                    timestamp: pendingTime
                ))
            }
            inTrackPoint = false
        case "wpt":
            if let lat = pendingLat, let lon = pendingLon {
                waypoints.append(Waypoint(
                    name: pendingWaypointName ?? "Waypoint \(waypoints.count + 1)",
                    latitude: lat,
                    longitude: lon,
                    elevation: pendingElevation
                ))
            }
            inWaypoint = false
        case "metadata", "trk":
            inMetadataOrTrackHeader = false
        default:
            break
        }
        currentText = ""
    }
}
