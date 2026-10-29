import Foundation

/// Every externally reachable destination in the app.
///
/// Foundation-only on purpose: widgets, live activities, notification extensions and App Intents
/// build URLs from this type, and the app's `AppRouter` turns it into navigation.
public enum DeepLink: Hashable, Sendable {
    case brews
    case brewDetail(id: String)
    case newBrew
    case settings
    case about
    /// Component gallery. Opens only in Debug builds.
    case designSystem
}

public extension DeepLink {
    /// Custom-scheme URL, e.g. `coffeemaster://brews/42`.
    /// Use for `widgetURL(_:)`, `Link`, Live Activity taps and notification payloads.
    var url: URL {
        DeepLinkParser().url(for: self)
    }
}
