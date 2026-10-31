import Foundation
import Observation
import Domain
import FactoryKit
@Observable
final class NewBrewViewModel {
    var method: BrewMethod
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

    /// `method`: preselected by the brew wizard's method pick.
    init(method: BrewMethod = .v60, router: any NewBrewRouting) {
        self.method = method
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
            router?.newBrewDidSave(brew)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var trimmedBeanName: String {
        beanName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
