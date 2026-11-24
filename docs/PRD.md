# Switchback
## Product Requirements Document (PRD)

Version: 1.0

---

# Executive Summary

Switchback is a navigation-first hiking application designed for hikers, backpackers, peakbaggers, and mountaineers who prioritize route planning, offline navigation, and outdoor competence over social media engagement.

Unlike existing hiking platforms that focus heavily on community growth, popularity metrics, and user engagement, Switchback focuses on route ownership, exploration, preparation, and safe navigation.

The primary goal is to provide a superior outdoor navigation experience on Apple devices while maintaining future compatibility with Android and web platforms.

---

# Product Vision

Switchback helps outdoor users confidently navigate trails, routes, and mountain objectives without requiring cellular service.

The app should feel like:

- The usability of Apple Maps
- The route ownership of GPX tools
- The reliability of dedicated GPS devices
- The mountain focus of Peakbagger
- The route depth of Gaia GPS

Without becoming another social media platform.

---

# Core Product Principles

## Navigation First

Navigation is the primary function of the application.

Every major design decision should improve route discovery, route management, navigation, or activity tracking.

---

## Offline by Default

Users should assume functionality will work without service.

Downloaded routes should include:

- Route geometry
- Maps
- Elevation data
- Route metadata
- Waypoints
- Route descriptions

---

## Competence Over Engagement

Switchback should encourage preparation and exploration rather than popularity.

The platform should avoid:

- Like counts
- Follower counts
- Trending routes
- Popularity rankings
- Influencer-oriented features

---

## User Ownership

Users should fully control:

- Their routes
- Their activities
- Their downloaded content
- Their summit history

GPX imports should be treated as first-class citizens.

---

# Target Platforms

## Phase 1

### iPhone (Primary)

Native SwiftUI application.

---

### Apple Watch

Companion navigation application.

Primary use cases:

- Off-route alerts
- Turn guidance
- Distance to waypoint
- Activity metrics
- Summit detection

---

## Phase 2

### iPad

Optimized planning experience.

---

### macOS

Route management and trip planning.

---

## Phase 3

### Web Application

Route management
GPX uploads
Trip planning
Activity history

---

### Android

Feature parity with iOS.

---

# Design Language

## Apple Liquid Glass

Switchback should fully embrace Apple's Liquid Glass design system.

### Requirements

- Native SwiftUI
- Liquid Glass materials
- Floating controls
- Layered depth effects
- Dynamic translucency
- Large map-focused layouts
- Minimal visual clutter

The map should always remain the primary visual element.

---

# Technical Architecture

## Map Provider

Mapbox

Reasons:

- Cross-platform support
- Offline capabilities
- GPX compatibility
- Future Android support
- Future web support
- Custom map layers

UI remains fully Apple-native while Mapbox powers mapping functionality.

---

# Navigation Structure

Primary Navigation Tabs:

1. Explore
2. Map
3. Record
4. Downloads
5. Profile

---

# Explore

Purpose:

Discover routes and hiking objectives.

Features:

- Search routes
- Search trails
- Search summits
- Filter by difficulty
- Filter by distance
- Filter by elevation gain
- Filter by region

No popularity-based sorting.

---

# Map

Primary application experience.

Features:

- Live location
- Route overlays
- GPX imports
- Downloaded routes
- Summit markers
- Waypoints
- Offline maps

Map remains accessible with minimal UI intrusion.

---

# Record

Activity tracking center.

Features:

- Start activity
- Pause activity
- Resume activity
- End activity

Track:

- Distance
- Duration
- Pace
- Elevation gain
- Elevation loss
- Current elevation
- Heart rate (when available)
- Weather conditions

---

# Downloads

Dedicated offline management system.

Sections:

## Downloaded Routes

Available offline.

---

## Active Routes

Currently in progress.

---

## Completed Activities

Historical records.

---

Downloads should never be mixed with completed activities.

---

# Profile

Personal outdoor history.

Contains:

- Activity history
- Summit collection
- Statistics
- Settings

Minimal social functionality.

---

# Route System

Routes are first-class objects.

Every route contains:

- Name
- Description
- GPX geometry
- Elevation profile
- Distance
- Elevation gain
- Waypoints
- Difficulty metadata

---

## Route Types

### Official Routes

Curated routes maintained by Switchback.

Examples:

- Standard mountain routes
- Established hiking trails

---

### Community Routes

User-submitted routes visible to others.

Subject to moderation.

---

### Private Routes

Visible only to owner.

Default for GPX imports.

Can optionally be shared later.

---

# GPX Import System

Users may import GPX files directly.

Supported sources:

- CalTopo
- Gaia GPS
- AllTrails
- Peakbagger
- Manual GPX exports

Imported routes become Switchback Route objects.

Users can:

- Rename routes
- Download routes
- Begin navigation
- Share routes
- Keep routes private

---

# Activity Tracking

Activities are the primary recorded object.

Workflow:

Start Activity
→ Navigate Route
→ Complete Activity
→ Save Activity

Stored data:

- Route used
- Duration
- Distance
- Pace
- Elevation gain
- Elevation loss
- Heart rate
- Weather conditions
- GPS track

---

# Summit Detection

Summits are secondary to activities.

Workflow:

Complete Activity
→ Analyze GPS Track
→ Detect Summit Visit
→ Add Summit to Collection

Users should not need to manually mark summits.

---

# Summit Collection

Automatically generated list.

Stores:

- Summit name
- Date reached
- Activity associated
- Elevation
- Region

Examples:

- Mount Bierstadt
- Mount Sherman
- Grays Peak
- Torreys Peak
- Granite Peak

---

# Apple Watch Experience

Primary Objective:

Reduce phone dependence during navigation.

---

## Off Route Detection

Watch continuously compares location against route geometry.

Example:

"Off Route
65 ft East
Turn West to Rejoin"

---

## Route Guidance

Examples:

"Waypoint Ahead"

"Summit in 0.2 Miles"

"Turn Left at Junction"

---

## Haptic Alerts

Used for:

- Route deviation
- Waypoint arrival
- Summit arrival
- Navigation warnings

---

## Watch Metrics

Display:

- Elapsed time
- Distance
- Pace
- Elevation
- Heart rate

---

# Route Downloads

A route package includes:

- Route geometry
- Topographic map tiles
- Elevation profile
- Waypoints
- Route metadata
- Route description

Everything required for offline navigation.

---

# Difficulty System

Information-focused.

No star ratings.

No popularity metrics.

Display:

- Distance
- Elevation gain
- Highest elevation
- Route type
- Navigation complexity
- Water availability
- Exposure level

Users decide for themselves.

---

# Progression Features (Phase 1)

Lightweight only.

Examples:

"Because you completed Mount Bierstadt, you may enjoy Mount Sherman."

No AI coaching.

No training plans.

No fitness programming.

---

# Social Features (Future)

Not included in initial release.

Possible future additions:

- Condition reports
- Route comments
- Trip reports
- Shared routes
- Friend activity

Must remain secondary to navigation.

---

# Monetization

Initial Goal:

Single Purchase Application

Premium upgrades only considered if recurring hosting costs require them.

Navigation features should never be locked behind subscriptions.

---

# Success Metrics

Primary Success Metrics:

- Routes downloaded
- Activities recorded
- Navigation sessions completed
- Offline navigation usage
- GPX imports

Not:

- Followers
- Likes
- Time spent in app
- Social engagement

---

# Product Mission Statement

Switchback exists to help outdoor users confidently explore trails, routes, and mountain objectives through reliable navigation, offline functionality, and thoughtful route management.

The app prioritizes preparedness, exploration, and self-reliance over popularity and engagement.
