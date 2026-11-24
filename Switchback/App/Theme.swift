import SwiftUI

/// Brand palette. Light/dark variants live in Assets.xcassets — navy and
/// sky swap roles across modes, olive lightens, and the orange route
/// accent stays fixed so routes always look the same on any map.
///
/// RouteAccent is reserved for the functional layer only: route lines,
/// active recording, and off-route alerts. Never use white text on it
/// (2.8:1) — use routeAccentText.
extension Color {
    static let brandPrimary = Color("BrandPrimary")
    static let brandSage = Color("BrandSage")
    static let brandNavy = Color("BrandNavy")
    static let brandSky = Color("BrandSky")
    static let routeAccent = Color("RouteAccent")
    static let routeAccentText = Color("RouteAccentText")
}
