import Foundation

/// A pour-over brew in progress: pour → pause (stir / swirl / shake) → pour … → stop, as on the
/// web's active screen. Everything is stored as timestamps, never as running timers, so the brew keeps
/// time correctly when the app is in the background: callers pass `now`, views redraw from it.
public struct PourOverSession: Equatable, Codable, Sendable {
    public enum Phase: Equatable, Codable, Sendable {
        /// Set up, nothing poured yet.
        case ready
        case pouring(since: Date)
        /// Between pours: the bed drains.
        case paused(since: Date)
        /// A timed action during a pause.
        case action(BrewAction, since: Date)
        /// AeroPress plunge; stopping it finishes the brew.
        case pressing(since: Date)
        case finished(at: Date)
    }

    /// An action stops by itself after this long (web: 15 s).
    public static let actionLimit: TimeInterval = 15
    /// Pauses shorter than this (a double tap between pour and pause) aren't logged.
    static let minimumPause: TimeInterval = 0.3
    /// The bloom takes about a quarter of the water (65 of 260 ml in the web app).
    static let bloomShare = 0.25

    public let setup: BrewSetup
    public private(set) var phase: Phase = .ready
    public private(set) var startedAt: Date?
    public private(set) var steps: [BrewStep] = []

    public init(setup: BrewSetup) {
        self.setup = setup
    }

    // MARK: - Actions

    /// Starts a pour (the first one starts the clock). Ends a running pause or action first.
    public mutating func pour(at now: Date) {
        switch phase {
        case .ready: startedAt = now
        case .paused, .action: closePause(at: now)
        case .pouring, .pressing, .finished: return
        }
        phase = .pouring(since: now)
    }

    /// Ends the current pour with what was poured (ml) and starts a pause.
    public mutating func pause(poured milliliters: Double, at now: Date) {
        guard case .pouring(let since) = phase else { return }
        record(.pour(milliliters: max(milliliters, 0)), from: since, to: now)
        phase = .paused(since: now)
    }

    /// Starts a timed action during a pause (another running action is finished first).
    public mutating func startAction(_ action: BrewAction, at now: Date) {
        guard isBetweenPours else { return }
        closePause(at: now)
        phase = .action(action, since: now)
    }

    /// Finishes the running action; the pause goes on.
    public mutating func finishAction(at now: Date) {
        guard case .action(let action, let since) = phase else { return }
        let end = min(now, since.addingTimeInterval(Self.actionLimit))
        record(.action(action), from: since, to: end)
        phase = .paused(since: end)
    }

    /// AeroPress: starts the plunge (from a pause).
    public mutating func startPress(at now: Date) {
        guard isBetweenPours else { return }
        closePause(at: now)
        phase = .pressing(since: now)
    }

    /// Ends the brew. A running pour is logged with `poured` ml; a running pause, action or plunge is
    /// logged too.
    public mutating func stop(poured milliliters: Double = 0, at now: Date) {
        switch phase {
        case .ready, .finished:
            return
        case .pouring:
            pause(poured: milliliters, at: now)
            closePause(at: now)
        case .paused, .action:
            closePause(at: now)
        case .pressing(let since):
            record(.action(.press), from: since, to: now)
        }
        phase = .finished(at: now)
    }

    /// Corrects how much a logged pour was.
    public mutating func editPour(at index: Int, milliliters: Double) {
        steps.setPour(at: index, milliliters: milliliters)
    }

    /// Runs time-based transitions: an action that hit `actionLimit` finishes by itself.
    public mutating func tick(at now: Date) {
        if case .action(_, let since) = phase, now.timeIntervalSince(since) >= Self.actionLimit {
            finishAction(at: now)
        }
    }

    // MARK: - Time

    public var isFinished: Bool {
        if case .finished = phase { true } else { false }
    }

    public var isBetweenPours: Bool {
        switch phase {
        case .paused, .action: true
        default: false
        }
    }

    public var isPouring: Bool {
        if case .pouring = phase { true } else { false }
    }

    public var isPressing: Bool {
        if case .pressing = phase { true } else { false }
    }

    /// The timed action running now, if any.
    public var runningAction: BrewAction? {
        if case .action(let action, _) = phase { action } else { nil }
    }

    /// When the current pour / pause / action / plunge began; `nil` before the start and after the end.
    public var phaseStartedAt: Date? {
        switch phase {
        case .pouring(let since), .paused(let since), .action(_, let since), .pressing(let since): since
        case .ready, .finished: nil
        }
    }

    /// Total brew time.
    public func elapsed(at now: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        if case .finished(let end) = phase { return end.timeIntervalSince(startedAt) }
        return max(now.timeIntervalSince(startedAt), 0)
    }

    /// Time in the current pour / pause / action / plunge; `nil` before the start and after the end.
    public func phaseElapsed(at now: Date) -> TimeInterval? {
        guard let phaseStartedAt else { return nil }
        let elapsed = max(now.timeIntervalSince(phaseStartedAt), 0)
        return runningAction == nil ? elapsed : min(elapsed, Self.actionLimit)
    }

    /// How long a pause usually takes, for the pause ring: a minute for fast drippers (V60, Chemex,
    /// AeroPress), half a minute for the rest, as in the web app.
    public var pauseTarget: TimeInterval {
        let name = setup.dripper?.name.lowercased() ?? ""
        return ["v60", "chemex", "aero"].contains(where: name.contains) ? 60 : 30
    }

    // MARK: - Water

    public var totalMilliliters: Double { Double(setup.waterMilliliters) }

    /// Water in logged pours.
    public var pouredMilliliters: Double { steps.totalPouredMilliliters }

    public var completedPours: Int {
        steps.pours.count
    }

    /// The pour being poured, or the next one (1-based).
    public var currentPourNumber: Int {
        if case .pouring = phase { return completedPours + 1 }
        return min(completedPours + 1, max(setup.pours, completedPours))
    }

    /// Planned water per pour: the bloom takes ~25 %, the other pours share the rest equally
    /// (rounded like the web app).
    public var plannedPours: [Double] {
        let total = totalMilliliters
        guard setup.pours > 1 else { return [total] }
        let bloom = (total * Self.bloomShare).rounded()
        let each = ((total - bloom) / Double(setup.pours - 1)).rounded()
        return [bloom] + Array(repeating: each, count: setup.pours - 1)
    }

    /// Where the next pours should end (ml), for marks on the progress bar: after the bloom, the
    /// water still to pour split evenly over the pours left. Empty before the bloom is done.
    public var nextPourMarks: [Double] {
        let left = setup.pours - completedPours
        let remaining = totalMilliliters - pouredMilliliters
        guard completedPours >= 1, left > 1, remaining > 0 else { return [] }
        let step = remaining / Double(left)
        return (1..<left).map { pouredMilliliters + step * Double($0) }.filter { $0 < totalMilliliters }
    }

    /// Where the running (or next) pour should end, in ml from the start: the bloom's share first, then
    /// the next mark (the last pour ends at the total). Nil once every planned pour is done.
    public var nextPourTarget: Double? {
        guard completedPours < setup.pours else { return nil }
        if completedPours == 0 { return plannedPours.first }
        return nextPourMarks.first ?? totalMilliliters
    }

    /// `milliliters` as a share of the total water (0...1).
    public func share(of milliliters: Double) -> Double {
        totalMilliliters > 0 ? min(milliliters / totalMilliliters, 1) : 0
    }

    /// The water-to-coffee ratio actually poured, when it's above the plan (web: shown in orange).
    public func ratioOverPlan(poured milliliters: Double) -> Double? {
        guard setup.doseGrams > 0 else { return nil }
        let ratio = milliliters / setup.doseGrams
        return ratio > setup.ratio + 0.05 ? ratio : nil
    }

    // MARK: - Private

    /// Logs the running pause (if long enough) up to `now`. A running action is logged first.
    private mutating func closePause(at now: Date) {
        switch phase {
        case .paused(let since):
            if now.timeIntervalSince(since) >= Self.minimumPause {
                record(.pause, from: since, to: now)
            }
        case .action:
            finishAction(at: now)
            closePause(at: now)
        default:
            break
        }
    }

    private mutating func record(_ kind: BrewStep.Kind, from start: Date, to end: Date) {
        let origin = startedAt ?? start
        steps.append(BrewStep(kind: kind, start: start.timeIntervalSince(origin), duration: max(end.timeIntervalSince(start), 0)))
    }
}
