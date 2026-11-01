import Foundation
import Observation
import Domain
import FactoryKit
@Observable
final class NewBrewViewModel {
    let setup: BrewSetup
    /// From the brew timer (empty when the form is opened without it).
    let steps: [BrewStep]
    var method: BrewMethod
    var beanName: String
    var doseGrams: Double
    var waterGrams: Double
    var brewTime: TimeInterval = 180
    /// 0...10, like the web app.
    var rating: Double = 8
    /// From the flavor wheel (Ukrainian names).
    var flavors: [String] = []
    var aromas: [String] = []
    var notes = ""

    private(set) var isSaving = false
    private(set) var errorMessage: String?

    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any NewBrewRouting)?

    /// `setup`: what the brew wizard chose (method, gear, recipe); `steps` and `totalTime`: what the
    /// brew timer recorded. They prefill the form; water is what was poured, if it was weighed.
    init(setup: BrewSetup = BrewSetup(method: .v60), steps: [BrewStep] = [], totalTime: TimeInterval? = nil, router: any NewBrewRouting) {
        self.setup = setup
        self.steps = steps
        method = setup.method
        beanName = setup.bean?.name ?? ""
        doseGrams = setup.doseGrams
        let poured = steps.totalPouredMilliliters
        waterGrams = poured > 0 ? poured : Double(setup.waterMilliliters)
        if let totalTime, totalTime > 0 { brewTime = totalTime.rounded() }
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
        var brew = setup.makeBrew(totalTime: brewTime, rating: rating, steps: steps)
        brew.method = method
        brew.bean = setup.bean?.name == trimmedBeanName ? setup.bean : BeanReference(name: trimmedBeanName)
        brew.doseGrams = doseGrams
        brew.ratio = waterGrams / doseGrams
        brew.flavors = flavors
        brew.aromas = aromas
        brew.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
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
