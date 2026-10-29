import Foundation

/// Simple user preferences shared across modules (Settings writes them, other modules read them).
public final class AppPreferences: Sendable {
    private enum Keys {
        static let haptics = "settings.hapticsEnabled"
    }

    // `UserDefaults` is documented as thread-safe but isn't marked `Sendable`.
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Vibration feedback (toasts, later timers). On by default.
    public var hapticsEnabled: Bool {
        get { defaults.object(forKey: Keys.haptics) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.haptics) }
    }
}
