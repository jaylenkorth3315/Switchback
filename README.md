# Switchback

Navigation-first hiking app for iPhone. Built around route ownership, activity recording, and summit tracking, with offline navigation as a future goal.

See [docs/PRD.md](docs/PRD.md) for the full product requirements.

## Project status

Active iPhone prototype, tested on a physical device. Built with SwiftUI, MapKit, SwiftData, and Core Location.

What works now:

- Import GPX tracks as routes or completed activities, with map previews and elevation profiles.
- Record an activity with location, distance, duration, and pace; pause and resume a recording.
- Browse routes, past activities, and nearby summits on a map.
- Detect visited summits from activity tracks and keep a summit history.

Offline map downloads and turn-by-turn navigation are product goals, not features of this prototype yet. The Downloads tab currently organizes saved routes and activities.

## Requirements

- Xcode 26+ (iOS 26 deployment target — the UI uses Liquid Glass APIs)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project

## Getting started

```sh
# Generate Switchback.xcodeproj from project.yml
xcodegen generate

# Open in Xcode
open Switchback.xcodeproj
```

If the active developer directory is the Command Line Tools, point it at Xcode first:

```sh
sudo xcode-select -s /Applications/Programming/Xcode.app/Contents/Developer
```

## Maps

The app currently uses MapKit. The PRD proposes Mapbox for future offline maps; that integration has not been implemented. The map layer is isolated in `Switchback/Features/Map/MapTabView.swift`. A future switch would involve:

1. Create a Mapbox account and tokens (secret token in `~/.netrc`, public token in Info.plist as `MBXAccessToken`).
2. Add the `mapbox-maps-ios` SwiftPM package to `project.yml` and regenerate.
3. Replace the MapKit `Map` in `MapTabView` with Mapbox's SwiftUI `Map`.

Never commit tokens to the repo.

## Structure

```
Switchback/
  App/          Entry point and root TabView
  Features/     One folder per tab (Explore, Map, Record, Downloads, Profile)
  Models/       SwiftData models: Route, Activity, Summit (+ TrackPoint, Waypoint)
  Services/     GPXParser, LocationService, RecordingSession, formatters
docs/           PRD and design docs
project.yml     XcodeGen project definition
```
