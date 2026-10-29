import Foundation

/// Every externally reachable destination in the app (deep link map v1).
///
/// Foundation-only on purpose: widgets, live activities, notification extensions and App Intents
/// build URLs from this type, and the app's `AppRouter` turns it into navigation.
///
/// | Link | Path |
/// |---|---|
/// | `journal` | `journal` |
/// | `brewDetail(id:)` | `journal/<brewId>` |
/// | `newBrew` | `brew/new` |
/// | `beans` | `beans` |
/// | `beanDetail(id:)` | `beans/<beanId>` |
/// | `devices` | `devices` |
/// | `profile` | `profile` |
/// | `achievements` | `profile/achievements` |
/// | `settings` | `settings` |
/// | `about` | `settings/about` |
/// | `designSystem` | `settings/design-system` (Debug builds only) |
public enum DeepLink: Hashable, Sendable {
    case journal
    case brewDetail(id: String)
    case newBrew
    case beans
    case beanDetail(id: String)
    case devices
    case profile
    case achievements
    case settings
    case about
    /// Component gallery. Opens only in Debug builds.
    case designSystem
}

public extension DeepLink {
    /// Custom-scheme URL, e.g. `coffeemaster://journal/42`.
    /// Use for `widgetURL(_:)`, `Link`, Live Activity taps and notification payloads.
    var url: URL {
        DeepLinkParser().url(for: self)
    }
}
