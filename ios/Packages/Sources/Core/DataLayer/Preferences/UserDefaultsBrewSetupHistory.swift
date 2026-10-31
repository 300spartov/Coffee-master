import Foundation
import Domain
import AppCore

/// `BrewSetupHistory` in `UserDefaults`: a small JSON list (one setup per method). It's a convenience
/// for prefilling, so a missing or unreadable value just means "no history".
public final class UserDefaultsBrewSetupHistory: BrewSetupHistory {
    static let key = "brew.recentSetups"

    // `UserDefaults` is documented as thread-safe but isn't marked `Sendable`.
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func recentSetups() async -> [BrewSetup] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        do {
            return try JSONDecoder().decode([BrewSetup].self, from: data)
        } catch {
            Log.data.error("Ignoring unreadable brew setup history: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    public func remember(_ setup: BrewSetup) async {
        let setups = await recentSetups().remembering(setup)
        do {
            defaults.set(try JSONEncoder().encode(setups), forKey: Self.key)
        } catch {
            Log.data.error("Couldn't save brew setup history: \(error.localizedDescription, privacy: .public)")
        }
    }
}
