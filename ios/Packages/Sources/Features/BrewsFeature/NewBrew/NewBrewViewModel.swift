import Foundation
import Observation
import Domain
import FactoryKit

@MainActor
@Observable
final class NewBrewViewModel {
    var method: BrewMethod = .v60
    var beanName = ""
    var doseGrams: Double = 15
    var waterGrams: Double = 250
    var brewTime: TimeInterval = 180
    /// 0...10, like the web app.
    var rating: Double = 8

    private(set) var isSaving = false
    private(set) var errorMessage: String?

    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any NewBrewRouting)?

    init(router: any NewBrewRouting) {
        self.router = router
    }

    var isValid: Bool {
        !trimmedBeanName.isEmpty && doseGrams > 0 && waterGrams > 0 && brewTime > 0
    }

    func save() async {
        guard isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let brew = Brew(
            method: method,
            bean: BeanReference(name: trimmedBeanName),
            doseGrams: doseGrams,
            ratio: waterGrams / doseGrams,
            totalTime: brewTime,
            rating: rating
        )
        do {
            try await repository.save(brew)
            router?.newBrewDidFinish(saved: brew)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel() {
        router?.newBrewDidFinish(saved: nil)
    }

    private var trimmedBeanName: String {
        beanName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
