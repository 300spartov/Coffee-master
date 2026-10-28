import Foundation

/// Runs a brew timer outside the app UI (Live Activity / Dynamic Island).
/// The ActivityKit implementation lives in `WidgetsShared`.
public protocol BrewTimerService: Sendable {
    func start(for brew: Brew) async throws
    func stop() async
}

public struct NoopBrewTimerService: BrewTimerService {
    public init() {}
    public func start(for brew: Brew) async throws {}
    public func stop() async {}
}
