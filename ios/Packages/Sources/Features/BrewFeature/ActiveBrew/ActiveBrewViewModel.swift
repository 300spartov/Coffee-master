import Foundation
import Observation
import Domain
import FactoryKit

/// Wizard step 4 for pour-over: the brew timer. The session keeps timestamps; `run()` refreshes
/// `now` a few times a second while the screen is visible, so the clocks move and an action
/// stops by itself at 15 s. Time is right after backgrounding because nothing counts intervals.
@Observable
final class ActiveBrewViewModel {
    /// A pour's target chip: the bloom, then the other pours.
    struct PourHint: Identifiable, Equatable {
        enum State { case done, active, upcoming }

        let number: Int
        /// Planned, or what was actually poured once done.
        let milliliters: Double
        let state: State

        var id: Int { number }
    }

    private(set) var session: PourOverSession {
        didSet {
            guard session != oldValue else { return }
            persist()
            syncLiveActivity()
        }
    }
    private(set) var now: Date
    /// Ml of the running pour, as typed (empty = not weighed; logged as 0 like the web app).
    var currentPour: Double? {
        didSet { if currentPour != oldValue { persist() } }
    }
    /// Back was tapped on a started brew.
    var isConfirmingLeave = false

    @ObservationIgnored private let clock: () -> Date
    /// The Live Activity's updates, in order (each waits for the previous one).
    @ObservationIgnored private var liveActivityUpdate: Task<Void, Never>?
    @ObservationIgnored @Injected(\.brewTimer) private var liveActivity
    @ObservationIgnored private weak var router: (any ActiveBrewRouting)?

    /// `clock`: the time source (tests pass a fixed one). `session` / `currentPour`: a brew in progress
    /// restored after an app kill.
    init(session: PourOverSession, currentPour: Double? = nil, router: any ActiveBrewRouting, clock: @escaping () -> Date = Date.init) {
        self.session = session
        self.currentPour = currentPour
        self.router = router
        self.clock = clock
        now = clock()
        syncLiveActivity()
    }

    /// A new brew with `setup`.
    convenience init(setup: BrewSetup, router: any ActiveBrewRouting, clock: @escaping () -> Date = Date.init) {
        self.init(session: PourOverSession(setup: setup), router: router, clock: clock)
    }

    /// Bound to the screen via `.task`.
    func run() async {
        await refreshWhileVisible { refresh() }
    }

    func refresh() {
        now = clock()
        session.tick(at: now)
    }

    // MARK: - What to show

    var isPouring: Bool { session.isPouring }

    /// "Bloom", "Pour 2", "Pause", "Stir", "Press" (the screen's phase label and the Live Activity's).
    var phaseTitle: String {
        switch session.phase {
        case .ready, .finished: tr("Phase")
        case .pouring: pourTitle(session.currentPourNumber)
        case .paused: tr("Pause")
        case .action(let action, _): action.title
        case .pressing: tr("Press")
        }
    }

    /// The brew as the Live Activity shows it, from the first pour until Stop.
    var liveStatus: BrewTimerStatus? {
        guard let startedAt = session.startedAt, !session.isFinished else { return nil }
        let symbol: String, phaseStart: Date?
        switch session.phase {
        case .pouring(let since): (symbol, phaseStart) = ("drop.fill", since)
        case .paused(let since): (symbol, phaseStart) = ("pause.fill", since)
        case .action(let action, let since): (symbol, phaseStart) = (action.systemImage, since)
        case .pressing(let since): (symbol, phaseStart) = ("arrow.down.circle.fill", since)
        case .ready, .finished: (symbol, phaseStart) = ("drop", nil)
        }
        let target = session.nextPourTarget.map { decimal($0) }
        return BrewTimerStatus(
            title: [session.setup.method.rawValue, session.setup.bean?.name].compactMap { $0 }.joined(separator: " · "),
            phaseTitle: phaseTitle,
            phaseSymbol: symbol,
            startedAt: startedAt,
            phaseStartedAt: phaseStart,
            progress: session.totalMilliliters > 0 ? min(session.pouredMilliliters / session.totalMilliliters, 1) : 0,
            target: target.map { tr("→ \($0) ml") }
        )
    }

    var isPressing: Bool {
        if case .pressing = session.phase { true } else { false }
    }

    var isAeropress: Bool { session.setup.aeropress != nil }

    func isRunning(_ action: BrewAction) -> Bool {
        if case .action(let running, _) = session.phase { running == action } else { false }
    }

    /// Poured so far, including the running pour as typed.
    var pouredMilliliters: Double {
        session.pouredMilliliters + (isPouring ? currentPour ?? 0 : 0)
    }

    var remainingMilliliters: Double { max(session.totalMilliliters - pouredMilliliters, 0) }

    var pouredFraction: Double {
        session.totalMilliliters > 0 ? min(pouredMilliliters / session.totalMilliliters, 1) : 0
    }

    /// The planned target of the running (or next) pour, shown as the ml field's placeholder.
    var currentPourTarget: Double? {
        let planned = session.plannedPours
        let index = session.currentPourNumber - 1
        return planned.indices.contains(index) ? planned[index] : nil
    }

    /// The pause ring: share of a typical pause gone.
    var pauseProgress: Double {
        guard case .paused = session.phase, let elapsed = session.phaseElapsed(at: now) else { return 0 }
        return min(elapsed / session.pauseTarget, 1)
    }

    var hints: [PourHint] {
        let poured = session.steps.pours
        let completed = session.completedPours
        let active: Int? = session.isFinished ? nil : session.currentPourNumber
        return session.plannedPours.enumerated().map { index, planned in
            let number = index + 1
            if number == active, number > completed {
                return PourHint(number: number, milliliters: planned, state: .active)
            }
            if number <= completed {
                return PourHint(number: number, milliliters: poured[index], state: .done)
            }
            return PourHint(number: number, milliliters: planned, state: .upcoming)
        }
    }

    // MARK: - Actions

    func pour() {
        session.pour(at: clock())
        currentPour = nil
        refresh()
    }

    func pause() {
        session.pause(poured: currentPour ?? 0, at: clock())
        currentPour = nil
        refresh()
    }

    /// Starts `action`, or finishes it if it's running.
    func toggle(_ action: BrewAction) {
        if isRunning(action) {
            session.finishAction(at: clock())
        } else {
            session.startAction(action, at: clock())
        }
        refresh()
    }

    /// AeroPress: starts the plunge; tapping again finishes the brew.
    func togglePress() {
        if isPressing {
            stop()
        } else {
            session.startPress(at: clock())
            refresh()
        }
    }

    func stop() {
        session.stop(poured: currentPour ?? 0, at: clock())
        currentPour = nil
        refresh()
        router?.activeBrewDidFinish(session)
    }

    func editPour(at index: Int, milliliters: Double) {
        session.editPour(at: index, milliliters: milliliters)
    }

    /// Back: leaves right away before the first pour; after that asks first (`isConfirmingLeave`).
    func didTapBack() {
        if session.startedAt == nil {
            router?.activeBrewDidLeave()
        } else {
            isConfirmingLeave = true
        }
    }

    func leave() {
        Task { [liveActivity] in await liveActivity.end() }
        router?.activeBrewDidLeave()
    }

    /// Mirrors the brew in the Live Activity; ends it once the brew is over.
    private func syncLiveActivity() {
        let status = liveStatus
        let previous = liveActivityUpdate
        liveActivityUpdate = Task { [liveActivity] in
            await previous?.value
            if let status { await liveActivity.show(status) } else { await liveActivity.end() }
        }
    }

    /// Keeps the brew across app kills once it has started; a finished one is the rating's to keep.
    private func persist() {
        guard session.startedAt != nil, !session.isFinished else { return }
        BrewInProgress.save(.timer(session, currentPour: currentPour))
    }
}
