import Foundation
import Observation
import Domain
import FactoryKit
@Observable
final class NewBrewViewModel {
    let setup: BrewSetup
    var method: BrewMethod
    var beanName: String
    var doseGrams: Double
    var waterGrams: Double
    var brewTime: TimeInterval = 180
    /// 0...10, like the web app.
    var rating: Double = 8

    private(set) var isSaving = false
    private(set) var errorMessage: String?

    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any NewBrewRouting)?

    /// `setup`: what the brew wizard chose so far (method, gear, recipe); its values prefill the form.
    init(setup: BrewSetup = BrewSetup(method: .v60), router: any NewBrewRouting) {
        self.setup = setup
        method = setup.method
        beanName = setup.bean?.name ?? ""
        doseGrams = setup.doseGrams
        waterGrams = Double(setup.waterMilliliters)
        self.router = router
    }

    var isValid: Bool {
        !trimmedBeanName.isEmpty && doseGrams > 0 && waterGrams > 0 && brewTime > 0
    }

    func save() async {
        guard isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        // The setup's gear and recipe, with what was edited here.
        var brew = setup.makeBrew(totalTime: brewTime, rating: rating)
        brew.method = method
        brew.bean = setup.bean?.name == trimmedBeanName ? setup.bean : BeanReference(name: trimmedBeanName)
        brew.doseGrams = doseGrams
        brew.ratio = waterGrams / doseGrams
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
