import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// A brew from the journal, every field editable (web: `edit-brew`): date, recipe, steps, rating, the
/// flavor wheel and notes. Saving runs `Brew.edited()` (steps back to back, total time from them).
@Observable
final class BrewFormViewModel {
    let brewID: Brew.ID
    private(set) var state: LoadState = .loading
    /// The brew as edited (a placeholder until it's loaded).
    var brew = Brew(method: .v60, doseGrams: 0, ratio: 0, rating: 0)
    private(set) var isSaving = false
    var alertMessage: String?

    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any BrewFormRouting)?

    init(brewID: Brew.ID, router: any BrewFormRouting) {
        self.brewID = brewID
        self.router = router
    }

    /// Loads once, so the edits survive the screen reappearing.
    func load() async {
        guard state != .ready else { return }
        do {
            brew = try await repository.fetch(id: brewID)
            state = .ready
        } catch RepositoryError.notFound {
            router?.brewFormNotFound(id: brewID)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Fields

    var isEspresso: Bool { brew.espresso != nil }

    /// The café, for drinks had out (`nil` for home brews).
    var cafePlace: String? {
        get { if case .cafe(let place) = brew.origin { place } else { nil } }
        set { if let newValue { brew.origin = .cafe(place: newValue) } }
    }

    var shotTime: Double {
        get { brew.espresso?.shotTime ?? 0 }
        set { brew.espresso?.shotTime = newValue }
    }

    var actualYield: Double? {
        get { brew.espresso?.actualYieldGrams }
        set { brew.espresso?.actualYieldGrams = newValue }
    }

    var grindSetting: Double? {
        get { brew.grindSetting.map(Double.init) }
        set { brew.grindSetting = newValue.map { Int($0.rounded()) } }
    }

    // MARK: - Steps

    /// The steps as they'll be saved (back to back), for the total under the list.
    var savedSteps: [BrewStep] { brew.steps.resequenced() }

    /// A new pour at the end (web: 50 ml, 15 s).
    func addStep() {
        brew.steps.append(BrewStep(kind: .pour(milliliters: 50), start: brew.steps.last?.end ?? 0, duration: 15))
    }

    func removeSteps(at offsets: IndexSet) {
        brew.steps.remove(atOffsets: offsets)
    }

    func step(at index: Int) -> BrewStep? {
        brew.steps.indices.contains(index) ? brew.steps[index] : nil
    }

    /// Changes a step (ignored once it's gone, e.g. while its row is being removed).
    func updateStep(at index: Int, _ change: (inout BrewStep) -> Void) {
        guard brew.steps.indices.contains(index) else { return }
        change(&brew.steps[index])
    }

    /// Turns a step into a pour or a pause (web: the step's type picker).
    func setPour(_ isPour: Bool, at index: Int) {
        updateStep(at: index) { step in
            if step.isPour != isPour { step.kind = isPour ? .pour(milliliters: 0) : .pause }
        }
    }

    // MARK: - Actions

    func save() async {
        guard state == .ready, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let edited = brew.edited()
        do {
            try await repository.save(edited)
            router?.brewFormDidSave(edited)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    /// Moves the brew to the trash (its coffee and filter go back to stock).
    func delete() async {
        do {
            try await repository.delete(id: brewID)
            router?.brewFormDidDelete(id: brewID)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
