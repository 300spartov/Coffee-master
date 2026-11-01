import Foundation
import os

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

/// Keeps the history in memory: the DI default for previews and tests.
public final class InMemoryBrewSetupHistory: BrewSetupHistory {
    private struct State {
        var setups: [BrewSetup]
        var espresso: [EspressoSetup]
    }

    private let state: OSAllocatedUnfairLock<State>

    public init(_ setups: [BrewSetup] = [], espresso: [EspressoSetup] = []) {
        state = OSAllocatedUnfairLock(initialState: State(setups: setups, espresso: espresso))
    }

    public func recentSetups() async -> [BrewSetup] { state.withLock { $0.setups } }
    public func remember(_ setup: BrewSetup) async { state.withLock { $0.setups = $0.setups.remembering(setup) } }
    public func recentEspressoSetups() async -> [EspressoSetup] { state.withLock { $0.espresso } }
    public func remember(_ setup: EspressoSetup) async { state.withLock { $0.espresso = $0.espresso.remembering(setup) } }
}
