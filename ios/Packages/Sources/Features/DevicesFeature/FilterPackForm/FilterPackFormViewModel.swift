import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// Add a pack of paper filters, or correct one you have (name, pack size, how many are left).
@Observable
final class FilterPackFormViewModel {
    enum Mode: Equatable {
        case add
        case edit(FilterPack.ID)
    }

    /// Pack sizes offered as chips (the web app's options).
    static let presetSizes = [25, 40, 50, 80, 100, 200, 350]
    static let sizeRange: ClosedRange<Double> = 1...1_000

    let mode: Mode
    var name = ""
    var total = Double(FilterPack.defaultCount)
    /// Edit mode only.
    var remaining = Double(FilterPack.defaultCount)
    private(set) var state: LoadState
    private(set) var isSaving = false
    var alertMessage: String?

    @ObservationIgnored @Injected(\.filterPackRepository) private var repository
    @ObservationIgnored private weak var router: (any FilterPackFormRouting)?

    init(mode: Mode, router: any FilterPackFormRouting) {
        self.mode = mode
        self.router = router
        state = mode == .add ? .ready : .loading
    }

    var isEditing: Bool { mode != .add }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isRemainingValid: Bool {
        !isEditing || (0...total).contains(remaining)
    }

    var isValid: Bool {
        !trimmedName.isEmpty && Self.sizeRange.contains(total) && isRemainingValid
    }

    func selectPreset(_ size: Int) {
        total = Double(size)
        if isEditing { remaining = min(remaining, total) }
    }

    func load() async {
        guard case .edit(let id) = mode else { return }
        state = .loading
        do {
            let pack = try await repository.fetch(id: id)
            name = pack.name
            total = Double(pack.total)
            remaining = Double(pack.remaining)
            state = .ready
        } catch RepositoryError.notFound {
            router?.filterPackFormNotFound(id: id)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func save() async {
        guard isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            var pack: FilterPack
            if case .edit(let id) = mode {
                // Edit the pack as it is now, so one removed elsewhere meanwhile isn't brought back.
                pack = try await repository.fetch(id: id)
                pack.name = trimmedName
                pack.total = Int(total)
                pack.remaining = min(max(Int(remaining), 0), pack.total)
            } else {
                pack = FilterPack(name: trimmedName, total: Int(total))
            }
            try await repository.save(pack)
            router?.filterPackFormDidFinish(saved: pack)
        } catch RepositoryError.notFound {
            if case .edit(let id) = mode { router?.filterPackFormNotFound(id: id) }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func cancel() {
        router?.filterPackFormDidFinish(saved: nil)
    }

    func delete() async {
        guard case .edit(let id) = mode else { return }
        do {
            try await repository.delete(id: id)
            router?.filterPackFormDidDelete(id: id)
        } catch RepositoryError.notFound {
            router?.filterPackFormNotFound(id: id)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
