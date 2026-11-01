import Foundation
import Testing
@testable import Domain

struct PourOverSessionTests {
    private let t0 = Date(timeIntervalSince1970: 1_000)
    private func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    private func session(_ method: BrewMethod = .v60, dripper: String? = nil, pours: Int = 3) -> PourOverSession {
        var setup = BrewSetup(method: method)
        setup.pours = pours
        setup.dripper = dripper.map { GearReference(name: $0) }
        return PourOverSession(setup: setup)
    }

    @Test func logsPoursPausesAndActionsOnOneClock() {
        var brew = session()
        brew.pour(at: at(0))
        brew.pause(poured: 50, at: at(10))
        brew.startAction(.stir, at: at(20))
        brew.finishAction(at: at(30))
        brew.pour(at: at(40))
        brew.pause(poured: 150, at: at(60))
        brew.stop(at: at(70))

        #expect(brew.steps == [
            BrewStep(kind: .pour(milliliters: 50), start: 0, duration: 10),
            BrewStep(kind: .pause, start: 10, duration: 10),
            BrewStep(kind: .action(.stir), start: 20, duration: 10),
            BrewStep(kind: .pause, start: 30, duration: 10),
            BrewStep(kind: .pour(milliliters: 150), start: 40, duration: 20),
            BrewStep(kind: .pause, start: 60, duration: 10),
        ])
        #expect(brew.elapsed(at: at(500)) == 70)
        #expect(brew.pouredMilliliters == 200)
        #expect(brew.isFinished)
    }

    /// Nothing counts intervals: time spent in the background is just the gap between timestamps.
    @Test func timeIsRightAfterBackgrounding() {
        var brew = session()
        brew.pour(at: at(0))
        brew.pause(poured: 60, at: at(12))

        #expect(brew.elapsed(at: at(312)) == 312)
        #expect(brew.phaseElapsed(at: at(312)) == 300)
    }

    @Test func tooShortPausesArentLogged() {
        var brew = session()
        brew.pour(at: at(0))
        brew.pause(poured: 60, at: at(5))
        brew.pour(at: at(5.1))

        #expect(brew.steps.map(\.kind) == [.pour(milliliters: 60)])
    }

    @Test func actionsStopThemselvesAt15Seconds() {
        var brew = session()
        brew.pour(at: at(0))
        brew.pause(poured: 60, at: at(10))
        brew.startAction(.swirl, at: at(11))
        brew.tick(at: at(20))
        #expect(brew.phase == .action(.swirl, since: at(11)))

        brew.tick(at: at(40))

        #expect(brew.phase == .paused(since: at(26)))
        #expect(brew.steps.last == BrewStep(kind: .action(.swirl), start: 11, duration: 15))
    }

    @Test func aeropressPressFinishesTheBrew() {
        var brew = session(.aeropress)
        brew.pour(at: at(0))
        brew.pause(poured: 200, at: at(10))
        brew.startPress(at: at(70))
        brew.stop(at: at(95))

        #expect(brew.steps.suffix(2).map(\.kind) == [.pause, .action(.press)])
        #expect(brew.steps.last?.duration == 25)
        #expect(brew.elapsed(at: at(200)) == 95)
    }

    @Test func stopWhilePouringLogsThePour() {
        var brew = session()
        brew.pour(at: at(0))
        brew.stop(poured: 80, at: at(15))

        #expect(brew.steps == [BrewStep(kind: .pour(milliliters: 80), start: 0, duration: 15)])
    }

    @Test func pourTargetsAndMarks() {
        var brew = session()
        // 16 g × 16 = 256 ml: bloom ~25 %, then two equal pours.
        #expect(brew.plannedPours == [64, 96, 96])
        #expect(brew.nextPourMarks.isEmpty)
        #expect(brew.nextPourTarget == 64)
        #expect(session(pours: 1).plannedPours == [256])

        brew.pour(at: at(0))
        brew.pause(poured: 64, at: at(10))
        #expect(brew.nextPourMarks == [160])
        #expect(brew.nextPourTarget == 160)
        #expect(brew.currentPourNumber == 2)

        brew.pour(at: at(40))
        brew.pause(poured: 96, at: at(60))
        #expect(brew.nextPourTarget == 256)
        brew.pour(at: at(80))
        brew.pause(poured: 96, at: at(100))
        #expect(brew.nextPourTarget == nil)
    }

    @Test func ratioOverPlanAndEdits() {
        var brew = session()
        #expect(brew.ratioOverPlan(poured: 256) == nil)
        #expect(brew.ratioOverPlan(poured: 288) == 18)

        brew.pour(at: at(0))
        brew.pause(poured: 60, at: at(10))
        brew.editPour(at: 0, milliliters: 70)

        #expect(brew.pouredMilliliters == 70)
    }

    @Test func pauseTargetFollowsTheDripper() {
        #expect(session(dripper: "Hario V60 02").pauseTarget == 60)
        #expect(session(dripper: "Kalita Wave 185").pauseTarget == 30)
    }
}
