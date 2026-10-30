import Foundation
import Observation
import Domain
import FactoryKit

/// Add or edit a coffee bag. Saving goes through the repository, which stamps `updatedAt`
/// (the web app's `_upd`) so the edit wins in sync. Roaster and name are remembered for autocomplete.
@Observable
final class BeanFormViewModel {
    enum Mode: Equatable {
        case add
        case edit(Bean.ID)
    }

    enum State: Equatable {
        case loading
        case ready
        case failed(String)
    }

    let mode: Mode
    private(set) var state: State

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

    private(set) var isSaving = false
    private(set) var remainingGrams: Double?
    var alertMessage: String?

    // Autocomplete
    private(set) var roasterSuggestions: [String] = []
    private(set) var nameSuggestions: [String] = []

    @ObservationIgnored @Injected(\.beanRepository) private var repository
    @ObservationIgnored @Injected(\.suggestionsRepository) private var suggestions
    @ObservationIgnored private weak var router: (any BeanFormRouting)?

    init(mode: Mode, router: any BeanFormRouting) {
        self.mode = mode
        self.router = router
        state = mode == .add ? .ready : .loading
    }

    var isEditing: Bool { mode != .add }

    static let scoreRange: ClosedRange<Double> = 0...100

    var isScoreValid: Bool {
        score.map(Self.scoreRange.contains) ?? true
    }

    var isValid: Bool {
        !trimmed(name).isEmpty && totalGrams > 0 && isScoreValid
    }

    /// Loads the bean being edited and the autocomplete values.
    func load() async {
        await loadSuggestions()
        guard case .edit(let id) = mode else { return }
        do {
            let bean = try await repository.fetch(id: id)
            fill(from: bean)
            state = .ready
        } catch RepositoryError.notFound {
            router?.beanFormNotFound(id: id)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func save() async {
        guard isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            // Edit the bag as it is now (not as it was when the form opened), so a bag removed or
            // changed elsewhere meanwhile isn't brought back or overwritten.
            var current: Bean?
            if case .edit(let id) = mode {
                current = try await repository.fetch(id: id)
            }
            let bean = makeBean(from: current)
            try await repository.save(bean)
            try? await suggestions.remember(Suggestions(roasters: [bean.roaster], beanNames: [bean.name]))
            router?.beanFormDidFinish(saved: bean)
        } catch RepositoryError.notFound {
            if case .edit(let id) = mode { router?.beanFormNotFound(id: id) }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func cancel() {
        router?.beanFormDidFinish(saved: nil)
    }

    func delete() async {
        guard case .edit(let id) = mode else { return }
        do {
            try await repository.delete(id: id)
            router?.beanFormDidDelete(id: id)
        } catch {
            alertMessage = error.localizedDescription
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
        var bean = current ?? Bean(name: trimmed(name), totalGrams: totalGrams)
        if current != nil, bean.totalGrams != totalGrams {
            bean.resize(totalGrams: totalGrams)
        }
        bean.name = trimmed(name)
        bean.roaster = trimmed(roaster)
        bean.roastProfile = roastProfile
        bean.country = trimmed(country)
        bean.farm = trimmed(farm)
        bean.process = process
        bean.score = score
        bean.descriptors = trimmed(descriptors)
        return bean
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
