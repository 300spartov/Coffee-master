import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// Add a pack of paper filters, or correct one you have (name, brewer it fits, pack size, how many are left).
@Observable
final class FilterPackFormViewModel: SavingViewModel {
    enum Mode: Equatable {
        case add
        case edit(FilterPack.ID)
    }

    /// Pack sizes offered as chips (the web app's options).
    static let presetSizes = [25, 40, 50, 80, 100, 200, 350]
    static let sizeRange: ClosedRange<Double> = 1...1_000

    let mode: Mode
    var name = ""
    /// The brewer the filters are for; `nil` = any.
    var shape: FilterShape?
    var total = Double(FilterPack.defaultCount)
    /// Edit mode only.
    var remaining = Double(FilterPack.defaultCount)
    private(set) var state: LoadState
    var isSaving = false
    var alertMessage: String?

    @ObservationIgnored @Injected(\.filterPackRepository) private var repository
    @ObservationIgnored private weak var router: (any FilterPackFormRouting)?

    /// `shape`: preselected for a new pack (e.g. Chemex when adding from a Chemex brew).
    init(mode: Mode, shape: FilterShape? = nil, router: any FilterPackFormRouting) {
        self.mode = mode
        self.shape = shape
        self.router = router
        state = mode == .add ? .ready : .loading
    }

    private var editingID: FilterPack.ID? {
        if case .edit(let id) = mode { id } else { nil }
    }

    var isEditing: Bool { editingID != nil }

    var isRemainingValid: Bool {
        !isEditing || (0...total).contains(remaining)
    }

    var isValid: Bool {
        !name.trimmed.isEmpty && Self.sizeRange.contains(total) && isRemainingValid
    }

    func selectPreset(_ size: Int) {
        total = Double(size)
        if isEditing { remaining = min(remaining, total) }
    }

    /// Loads the pack being edited, once.
    func load() async {
        guard let id = editingID, state != .ready else { return }
        do {
            let pack = try await repository.fetch(id: id)
            (name, shape, total, remaining) = (pack.name, pack.shape, Double(pack.total), Double(pack.remaining))
            state = .ready
        } catch RepositoryError.notFound {
            router?.filterPackForm(didFinish: .notFound)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func save() async {
        guard isValid else { return }
        await whileSaving {
            var saved: FilterPack?
            await attempt({
                // The pack as it is now, so one removed elsewhere meanwhile isn't brought back.
                var pack = try await repository.fetch(id: editingID) ?? FilterPack(name: name.trimmed, total: Int(total), shape: shape)
                pack.name = name.trimmed
                pack.shape = shape
                if isEditing {
                    pack.total = Int(total)
                    pack.remaining = Int(remaining).clamped(to: 0...pack.total)
                }
                try await repository.save(pack)
                saved = pack
            }, notFound: { router?.filterPackForm(didFinish: .notFound) })
            if let saved { router?.filterPackForm(didFinish: .saved(saved, editing: isEditing)) }
        }
    }

    func cancel() {
        router?.filterPackForm(didFinish: .cancelled)
    }

    func delete() async {
        guard let id = editingID else { return }
        if await attempt({ try await repository.delete(id: id) }, notFound: { router?.filterPackForm(didFinish: .notFound) }) {
            router?.filterPackForm(didFinish: .deleted(id))
        }
    }
}
