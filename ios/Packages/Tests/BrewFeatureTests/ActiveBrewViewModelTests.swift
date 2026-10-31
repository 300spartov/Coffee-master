import Foundation
import Testing
import Domain
@testable import BrewFeature

@MainActor
final class SpyActiveRouter: ActiveBrewRouting {
    private(set) var finished: [PourOverSession] = []
    private(set) var leaveCount = 0

    func activeBrewDidFinish(_ session: PourOverSession) { finished.append(session) }
    func activeBrewDidLeave() { leaveCount += 1 }
}

@MainActor
struct ActiveBrewViewModelTests {
    private let router = SpyActiveRouter()

    /// A clock the test moves by hand.
    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
        func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
    }

    private func makeViewModel(_ clock: Clock, method: BrewMethod = .v60) -> ActiveBrewViewModel {
        ActiveBrewViewModel(setup: BrewSetup(method: method), router: router, clock: { clock.now })
    }

    @Test func pourAndPauseUseTheTypedAmountAndMoveTheHints() {
        let clock = Clock()
        let viewModel = makeViewModel(clock)
        #expect(viewModel.hints.map(\.state) == [.active, .upcoming, .upcoming])
        #expect(viewModel.currentPourTarget == 64)

        viewModel.pour()
        viewModel.currentPour = 70
        #expect(viewModel.pouredMilliliters == 70)
        clock.advance(10)
        viewModel.pause()

        #expect(viewModel.session.steps.first?.kind == .pour(milliliters: 70))
        #expect(viewModel.currentPour == nil)
        #expect(viewModel.hints.map(\.state) == [.done, .active, .upcoming])
        #expect(viewModel.hints.first?.milliliters == 70)
        #expect(viewModel.remainingMilliliters == 186)
    }

    @Test func untypedPourIsLoggedAsZero() {
        let clock = Clock()
        let viewModel = makeViewModel(clock)
        viewModel.pour()
        clock.advance(10)
        viewModel.pause()

        #expect(viewModel.session.steps.first?.kind == .pour(milliliters: 0))
    }

    @Test func actionToggleAndAutoStop() {
        let clock = Clock()
        let viewModel = makeViewModel(clock)
        viewModel.pour()
        clock.advance(10)
        viewModel.pause()

        viewModel.toggle(.stir)
        #expect(viewModel.isRunning(.stir))
        clock.advance(20)
        viewModel.refresh()

        #expect(!viewModel.isRunning(.stir))
        #expect(viewModel.session.steps.last?.duration == 15)
    }

    @Test func aeropressPressTwiceFinishes() {
        let clock = Clock()
        let viewModel = makeViewModel(clock, method: .aeropress)
        viewModel.pour()
        clock.advance(10)
        viewModel.pause()

        viewModel.togglePress()
        #expect(viewModel.isPressing)
        clock.advance(30)
        viewModel.togglePress()

        #expect(router.finished.first?.steps.last?.kind == .action(.press))
    }

    @Test func stopRoutesTheFinishedSession() {
        let clock = Clock()
        let viewModel = makeViewModel(clock)
        viewModel.pour()
        clock.advance(42)
        viewModel.currentPour = 256
        viewModel.stop()

        let session = router.finished.first
        #expect(session?.isFinished == true)
        #expect(session?.elapsed(at: .distantFuture) == 42)
        #expect(session?.pouredMilliliters == 256)
    }

    @Test func backLeavesBeforeTheStartAndAsksAfter() {
        let clock = Clock()
        let viewModel = makeViewModel(clock)
        viewModel.didTapBack()
        #expect(router.leaveCount == 1)

        viewModel.pour()
        viewModel.didTapBack()
        #expect(router.leaveCount == 1)
        #expect(viewModel.isConfirmingLeave)
        viewModel.leave()
        #expect(router.leaveCount == 2)
    }
}
