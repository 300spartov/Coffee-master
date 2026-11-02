import Foundation

/// The setups the user started brews with, so the next brew can start from the last one.
public protocol BrewSetupHistory: Sendable {
    /// Pour-over setups, newest first, at most one per method.
    func recentSetups() async -> [BrewSetup]
    func remember(_ setup: BrewSetup) async
    /// Espresso setups, newest first, at most one per drink.
    func recentEspressoSetups() async -> [EspressoSetup]
    func remember(_ setup: EspressoSetup) async
}

/// A setup kept per method in the history.
public protocol RememberedSetup: Codable, Sendable {
    var method: BrewMethod { get }
}

extension BrewSetup: RememberedSetup {}
extension EspressoSetup: RememberedSetup {}

public extension Array where Element: RememberedSetup {
    /// `setup` first, replacing the older one for its method, keeping at most `limit`.
    func remembering(_ setup: Element, limit: Int = 20) -> [Element] {
        Array(([setup] + filter { $0.method != setup.method }).prefix(limit))
    }
}

/// The history in a `DraftStore` (UserDefaults in the app, memory in previews and tests). It's a
/// convenience for prefilling, so a missing or unreadable list just means "no history".
public struct StoredBrewSetupHistory: BrewSetupHistory {
    static let key = "brew.recentSetups"
    static let espressoKey = "brew.recentEspressoSetups"

    private let store: any DraftStore

    public init(store: any DraftStore = InMemoryDraftStore()) {
        self.store = store
    }

    public func recentSetups() async -> [BrewSetup] { load(Self.key) }
    public func remember(_ setup: BrewSetup) async { store.save(load(Self.key).remembering(setup), key: Self.key) }
    public func recentEspressoSetups() async -> [EspressoSetup] { load(Self.espressoKey) }
    public func remember(_ setup: EspressoSetup) async { store.save(load(Self.espressoKey).remembering(setup), key: Self.espressoKey) }

    private func load<Setup: RememberedSetup>(_ key: String) -> [Setup] {
        store.load([Setup].self, key: key) ?? []
    }
}
