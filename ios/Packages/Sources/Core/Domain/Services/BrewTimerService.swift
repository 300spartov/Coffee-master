import Foundation

/// Mirrors the running brew outside the app (a Live Activity on the Lock Screen and in the Dynamic
/// Island). The brew screens call it as the brew changes; it never drives the brew.
public protocol BrewTimerService: Sendable {
    /// Shows `status`, starting the activity if there's none yet.
    func show(_ status: BrewTimerStatus) async
    func end() async
}

/// No Live Activity: the DI default for previews and tests.
public struct NoopBrewTimerService: BrewTimerService {
    public init() {}
    public func show(_ status: BrewTimerStatus) async {}
    public func end() async {}
}

/// What the Live Activity shows for a running brew. Texts come localized from the app (the extension
/// can't read the in-app language). Clocks are start dates, so the system keeps them ticking without
/// updates; the app only updates on a new phase.
public struct BrewTimerStatus: Codable, Hashable, Sendable {
    /// "V60 · Kenya".
    public var title: String
    /// "Pour 2", "Pause", "Stir".
    public var phaseTitle: String
    /// SF Symbol for the phase.
    public var phaseSymbol: String
    public var startedAt: Date
    /// Start of the current phase (nil once the brew is over).
    public var phaseStartedAt: Date?
    /// Water poured, 0...1.
    public var progress: Double
    /// Where the running or next pour should end, e.g. "→ 160 ml" (nil when all is poured).
    public var target: String?

    public init(title: String, phaseTitle: String, phaseSymbol: String, startedAt: Date, phaseStartedAt: Date?, progress: Double, target: String?) {
        self.title = title
        self.phaseTitle = phaseTitle
        self.phaseSymbol = phaseSymbol
        self.startedAt = startedAt
        self.phaseStartedAt = phaseStartedAt
        self.progress = progress
        self.target = target
    }
}
