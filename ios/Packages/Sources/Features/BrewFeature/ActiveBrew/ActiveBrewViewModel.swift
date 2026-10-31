import Foundation
import Observation
import Domain

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

    private(set) var session: PourOverSession
    private(set) var now: Date
    /// Ml of the running pour, as typed (empty = not weighed; logged as 0 like the web app).
    var currentPour: Double?
    /// Back was tapped on a started brew.
    var isConfirmingLeave = false

    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private weak var router: (any ActiveBrewRouting)?

    /// `clock`: the time source (tests pass a fixed one).
    init(setup: BrewSetup, router: any ActiveBrewRouting, clock: @escaping () -> Date = Date.init) {
        session = PourOverSession(setup: setup)
        self.router = router
        self.clock = clock
        now = clock()
    }

    /// Bound to the screen via `.task`.
    func run() async {
        while !Task.isCancelled {
            refresh()
            try? await Task.sleep(for: .milliseconds(200))
        }
    }

    func refresh() {
        now = clock()
        session.tick(at: now)
    }

    // MARK: - What to show

    var isPouring: Bool {
        if case .pouring = session.phase { true } else { false }
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
        let poured = session.steps.compactMap { step -> Double? in
            if case .pour(let milliliters) = step.kind { milliliters } else { nil }
        }
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
        router?.activeBrewDidLeave()
    }
}
