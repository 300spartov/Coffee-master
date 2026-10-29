import Foundation
import Observation
import Domain
import FactoryKit

@MainActor
@Observable
final class BrewDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(Brew)
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var isTimerRunning = false
    var alertMessage: String?

    @ObservationIgnored private let brewID: Brew.ID
    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored @Injected(\.brewTimer) private var brewTimer
    @ObservationIgnored private weak var router: (any BrewDetailRouting)?

    init(brewID: Brew.ID, router: any BrewDetailRouting) {
        self.brewID = brewID
        self.router = router
    }

    func load() async {
        do {
            state = .loaded(try await repository.fetch(id: brewID))
        } catch RepositoryError.notFound {
            state = .failed(tr("This brew no longer exists."))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleTimer() async {
        guard case .loaded(let brew) = state else { return }
        if isTimerRunning {
            await brewTimer.stop()
            isTimerRunning = false
        } else {
            do {
                try await brewTimer.start(for: brew)
                isTimerRunning = true
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    func delete() async {
        do {
            if isTimerRunning { await brewTimer.stop() }
            try await repository.delete(id: brewID)
            router?.brewDetailDidDelete(id: brewID)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
