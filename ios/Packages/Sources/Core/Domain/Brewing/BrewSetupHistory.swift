import Foundation
import os

/// The setups the user started brews with, so the next brew can start from the last one.
public protocol BrewSetupHistory: Sendable {
    /// Newest first, at most one per method.
    func recentSetups() async -> [BrewSetup]
    func remember(_ setup: BrewSetup) async
}

public extension Array where Element == BrewSetup {
    /// `setup` first, replacing the older one for its method, keeping at most `limit`.
    func remembering(_ setup: BrewSetup, limit: Int = 20) -> [BrewSetup] {
        Array(([setup] + filter { $0.method != setup.method }).prefix(limit))
    }
}

/// Keeps the history in memory: the DI default for previews and tests.
public final class InMemoryBrewSetupHistory: BrewSetupHistory {
    private let setups: OSAllocatedUnfairLock<[BrewSetup]>

    public init(_ setups: [BrewSetup] = []) {
        self.setups = OSAllocatedUnfairLock(initialState: setups)
    }

    public func recentSetups() async -> [BrewSetup] { setups.withLock { $0 } }

    public func remember(_ setup: BrewSetup) async {
        setups.withLock { $0 = $0.remembering(setup) }
    }
}
