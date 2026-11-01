import Foundation
import Domain
import AppCore

/// `BrewSetupHistory` in `UserDefaults`: small JSON lists (one setup per method). It's a convenience
/// for prefilling, so a missing or unreadable value just means "no history".
public final class UserDefaultsBrewSetupHistory: BrewSetupHistory {
    static let key = "brew.recentSetups"
    static let espressoKey = "brew.recentEspressoSetups"

    // `UserDefaults` is documented as thread-safe but isn't marked `Sendable`.
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func recentSetups() async -> [BrewSetup] { load(Self.key) }
    public func remember(_ setup: BrewSetup) async { store(load(Self.key).remembering(setup), Self.key) }
    public func recentEspressoSetups() async -> [EspressoSetup] { load(Self.espressoKey) }
    public func remember(_ setup: EspressoSetup) async { store(load(Self.espressoKey).remembering(setup), Self.espressoKey) }

    private func load<Setup: RememberedSetup>(_ key: String) -> [Setup] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([Setup].self, from: data)
        } catch {
            Log.data.error("Ignoring unreadable brew setup history: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func store<Setup: RememberedSetup>(_ setups: [Setup], _ key: String) {
        do {
            defaults.set(try JSONEncoder().encode(setups), forKey: key)
        } catch {
            Log.data.error("Couldn't save brew setup history: \(error.localizedDescription, privacy: .public)")
        }
    }
}
