import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// A brew in the journal, every field editable (web: `edit-brew`), or one logged after the fact (web:
/// `log-brew`: at home or at a café). Saving runs `Brew.edited()` (steps back to back, total time).
@Observable
final class BrewFormViewModel: AlertingViewModel {
    enum Mode: Equatable {
        /// Logged after the fact.
        case add
        case edit(Brew.ID)
    }

    let mode: Mode
    private(set) var state: LoadState
    /// The brew as edited (when editing, a placeholder until it's loaded).
    var brew: Brew
    private(set) var isSaving = false
    var alertMessage: String?

    // Logging: the bag and grinder are typed, with your own as suggestions (a match links the brew).
    var beanName = ""
    var grinderName = ""
    private(set) var beans: [Bean] = []
    private(set) var grinders: [Device] = []

    @ObservationIgnored private var didLoad = false
    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored @Injected(\.beanRepository) private var beanRepository
    @ObservationIgnored @Injected(\.deviceRepository) private var devices
    @ObservationIgnored private weak var router: (any BrewFormRouting)?

    init(mode: Mode, router: any BrewFormRouting, now: Date = .now) {
        self.mode = mode
        self.router = router
        state = mode == .add ? .ready : .loading
        brew = .logged(at: now)
    }

    var isAdding: Bool { mode == .add }

    /// Loads once, so the edits survive the screen reappearing: the brew, or your bags and grinders.
    func load() async {
        guard !didLoad else { return }
        switch mode {
        case .add:
            didLoad = true
            beans = (try? await beanRepository.fetchAll()) ?? []
            grinders = (try? await devices.fetchAll(of: .grinder)) ?? []
        case .edit(let id):
            do {
                brew = try await repository.fetch(id: id)
                didLoad = true
                state = .ready
            } catch RepositoryError.notFound {
                router?.brewFormNotFound(id: id)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    /// Methods to log: the wizard's, alternative then espresso.
    var methods: [BrewMethod] { BrewMethod.alternativePresets + BrewMethod.espressoPresets }

    /// Home or café (logging): a café drink has no recipe, only its volume.
    var isCafe: Bool {
        get { brew.isCafeVisit }
        set {
            guard newValue != brew.isCafeVisit else { return }
            let home = Brew.logged()
            brew.origin = newValue ? .cafe(place: "") : .home
            brew.doseGrams = newValue ? 0 : home.doseGrams
            brew.ratio = newValue ? 0 : home.ratio
            brew.waterTemperature = newValue ? nil : home.waterTemperature
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

    /// Edits are saved as they are; a logged home brew made with one of your bags takes its dose
    /// from it (`record`), so deleting it later gives the coffee back evenly.
    func save() async {
        guard state == .ready, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let saved = (isAdding ? loggedBrew() : brew).edited()
        if await attempt({ if isAdding { try await repository.record(saved) } else { try await repository.save(saved) } }) {
            router?.brewFormDidSave(saved)
        }
    }

    func cancel() {
        router?.brewFormDidCancel()
    }

    /// Moves the brew to the trash, with Undo (`trashBrew`).
    func delete() async {
        guard case .edit(let id) = mode else { return }
        if await attempt({ try await trashBrew(id: id) }) {
            router?.brewFormDidDelete(id: id)
        }
    }

    /// The brew with the typed bag and grinder: one of yours (by name) is linked; a café drink's bag
    /// is only named (it's not from your stock).
    private func loggedBrew() -> Brew {
        var logged = brew
        let bean = beanName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ownedBean = brew.isCafeVisit ? nil : beans.first { $0.name.caseInsensitiveCompare(bean) == .orderedSame }
        logged.bean = ownedBean.map(BeanReference.init) ?? (bean.isEmpty ? nil : BeanReference(name: bean))
        let grinder = grinderName.trimmingCharacters(in: .whitespacesAndNewlines)
        if brew.isCafeVisit || grinder.isEmpty {
            logged.grinder = nil
            logged.grindSetting = nil
        } else {
            logged.grinder = grinders.first { Device.namesMatch($0.name, grinder) }.map(GearReference.init) ?? GearReference(name: grinder)
        }
        if case .cafe(let place) = brew.origin {
            logged.origin = .cafe(place: place.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return logged
    }
}
