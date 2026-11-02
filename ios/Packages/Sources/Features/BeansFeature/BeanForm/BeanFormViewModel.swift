import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// Add or edit a coffee bag. Saving goes through the repository, which stamps `updatedAt`
/// (the web app's `_upd`) so the edit wins in sync. Roaster and name are remembered for autocomplete.
@Observable
final class BeanFormViewModel: SavingViewModel {
    enum Mode: Equatable {
        case add
        case edit(Bean.ID)
    }

    let mode: Mode
    private(set) var state: LoadState

    // Fields
    var name = ""
    var roaster = ""
    var totalGrams: Double = Bean.defaultBagGrams
    var roastProfile: RoastProfile?
    var country = ""
    var farm = ""
    var process: ProcessingMethod?
    /// 0...100, optional.
    var score: Double?
    var descriptors = ""

    var isSaving = false
    private(set) var remainingGrams: Double?
    var alertMessage: String?

    // Autocomplete
    private(set) var roasterSuggestions: [String] = []
    private(set) var nameSuggestions: [String] = []

    @ObservationIgnored private var didLoad = false
    @ObservationIgnored @Injected(\.beanRepository) private var repository
    @ObservationIgnored @Injected(\.suggestionsRepository) private var suggestions
    @ObservationIgnored private weak var router: (any BeanFormRouting)?

    init(mode: Mode, router: any BeanFormRouting) {
        self.mode = mode
        self.router = router
        state = mode == .add ? .ready : .loading
    }

    private var editingID: Bean.ID? {
        if case .edit(let id) = mode { id } else { nil }
    }

    var isEditing: Bool { editingID != nil }

    static let scoreRange: ClosedRange<Double> = 0...100

    var isScoreValid: Bool {
        score.map(Self.scoreRange.contains) ?? true
    }

    var isValid: Bool {
        !name.trimmed.isEmpty && totalGrams > 0 && isScoreValid
    }

    /// Loads the autocomplete values and the bean being edited, once (so coming back to the screen
    /// doesn't overwrite what was typed).
    func load() async {
        guard !didLoad else { return }
        await loadSuggestions()
        guard let id = editingID else {
            didLoad = true
            return
        }
        do {
            fill(from: try await repository.fetch(id: id))
            didLoad = true
            state = .ready
        } catch RepositoryError.notFound {
            router?.beanForm(didFinish: .notFound)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func save() async {
        guard isValid else { return }
        await whileSaving {
            var saved: Bean?
            await attempt({
                // The bag as it is now (not as it was when the form opened), so a bag removed or
                // changed elsewhere meanwhile isn't brought back or overwritten.
                let bean = makeBean(from: try await repository.fetch(id: editingID))
                try await repository.save(bean)
                try? await suggestions.remember(Suggestions(roasters: [bean.roaster], beanNames: [bean.name]))
                saved = bean
            }, notFound: { router?.beanForm(didFinish: .notFound) })
            if let saved { router?.beanForm(didFinish: .saved(saved, editing: isEditing)) }
        }
    }

    func cancel() {
        router?.beanForm(didFinish: .cancelled)
    }

    func delete() async {
        guard let id = editingID else { return }
        if await attempt({ try await repository.delete(id: id) }, notFound: { router?.beanForm(didFinish: .notFound) }) {
            router?.beanForm(didFinish: .deleted(id))
        }
    }

    // MARK: - Private

    private func loadSuggestions() async {
        let remembered = (try? await suggestions.suggestions()) ?? Suggestions()
        let beans = (try? await repository.fetchAll()) ?? []
        roasterSuggestions = remembered.roasters + beans.map(\.roaster)
        nameSuggestions = remembered.beanNames + beans.map(\.name)
    }

    private func fill(from bean: Bean) {
        name = bean.name
        roaster = bean.roaster
        totalGrams = bean.totalGrams
        roastProfile = bean.roastProfile
        country = bean.country
        farm = bean.farm
        process = bean.process
        score = bean.score
        descriptors = bean.descriptors
        remainingGrams = bean.remainingGrams
    }

    /// New bag (full), or `current` with the edits applied. A new bag size keeps the amount
    /// already used, like the web app.
    private func makeBean(from current: Bean?) -> Bean {
        var bean = current ?? Bean(name: name.trimmed, totalGrams: totalGrams)
        if current != nil, bean.totalGrams != totalGrams {
            bean.resize(totalGrams: totalGrams)
        }
        bean.name = name.trimmed
        bean.roaster = roaster.trimmed
        bean.roastProfile = roastProfile
        bean.country = country.trimmed
        bean.farm = farm.trimmed
        bean.process = process
        bean.score = score
        bean.descriptors = descriptors.trimmed
        return bean
    }
}
