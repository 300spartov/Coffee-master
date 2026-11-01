import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
@testable import BrewFeature

/// Records what the timer sends to the Live Activity.
actor SpyBrewTimer: BrewTimerService {
    private(set) var shown: [BrewTimerStatus] = []
    private(set) var endCount = 0

    func show(_ status: BrewTimerStatus) { shown.append(status) }
    func end() { endCount += 1 }
}

/// ROADMAP 2.4: the timer mirrors the brew in the Live Activity.
@Suite(.container)
@MainActor
struct LiveActivityTests {
    private let spy = SpyBrewTimer()

    init() {
        Container.shared.brewTimer.register { [spy] in spy }
        Container.shared.draftStore.register { InMemoryDraftStore() }
    }

    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    /// Lets the queued activity updates run.
    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
        try? await Task.sleep(for: .milliseconds(50))
    }

    @Test func phasesAreShownWithTheNextTarget() async throws {
        let clock = Clock()
        var setup = BrewSetup(method: .v60)
        setup.bean = BeanReference(name: "Kenya")
        let viewModel = ActiveBrewViewModel(setup: setup, router: SpyActiveRouter(), clock: { clock.now })

        viewModel.pour()
        clock.now.addTimeInterval(10)
        viewModel.currentPour = 64
        viewModel.pause()
        await settle()

        let shown = await spy.shown
        #expect(shown.map(\.phaseTitle) == ["Bloom", "Pause"])
        #expect(shown.first?.title == "V60 · Kenya")
        #expect(shown.first?.target == "→ 64 ml")
        #expect(shown.last?.target == "→ 160 ml")
        #expect(shown.last?.phaseSymbol == "pause.fill")
        #expect(shown.last?.progress == 0.25)
        #expect(shown.last?.startedAt == Date(timeIntervalSince1970: 1_000))
    }

    @Test func stopAndLeaveEndTheActivity() async {
        let viewModel = ActiveBrewViewModel(setup: BrewSetup(method: .v60), router: SpyActiveRouter())
        viewModel.pour()
        viewModel.stop()
        await settle()
        #expect(await spy.endCount >= 1)

        let other = ActiveBrewViewModel(setup: BrewSetup(method: .v60), router: SpyActiveRouter())
        other.pour()
        other.leave()
        await settle()
        #expect(await spy.endCount >= 2)
    }

    @Test func aRestoredBrewShowsItsActivityAgain() async {
        var session = PourOverSession(setup: BrewSetup(method: .v60))
        session.pour(at: .now)

        _ = ActiveBrewViewModel(session: session, router: SpyActiveRouter())
        await settle()

        #expect(await spy.shown.map(\.phaseTitle) == ["Bloom"])
    }
}
