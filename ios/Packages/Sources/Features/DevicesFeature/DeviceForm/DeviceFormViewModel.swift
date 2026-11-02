import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// Add a device that isn't in the catalog, or rename / recategorize one you own.
@Observable
final class DeviceFormViewModel: SavingViewModel {
    enum Mode: Equatable {
        case add(DeviceType)
        case edit(Device.ID)
    }

    let mode: Mode
    var name = ""
    var type: DeviceType
    private(set) var state: LoadState
    var isSaving = false
    var alertMessage: String?

    @ObservationIgnored @Injected(\.deviceRepository) private var repository
    @ObservationIgnored private weak var router: (any DeviceFormRouting)?

    init(mode: Mode, router: any DeviceFormRouting) {
        self.mode = mode
        self.router = router
        if case .add(let type) = mode {
            self.type = type
            state = .ready
        } else {
            type = .dripper
            state = .loading
        }
    }

    private var editingID: Device.ID? {
        if case .edit(let id) = mode { id } else { nil }
    }

    var isEditing: Bool { editingID != nil }
    var isValid: Bool { !name.trimmed.isEmpty }

    /// Loads the device being edited, once.
    func load() async {
        guard let id = editingID, state != .ready else { return }
        do {
            let device = try await repository.fetch(id: id)
            (name, type) = (device.name, device.type)
            state = .ready
        } catch RepositoryError.notFound {
            router?.deviceForm(didFinish: .notFound)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func save() async {
        guard isValid else { return }
        await whileSaving {
            let name = name.trimmed
            var saved: Device?
            await attempt({
                let current = try await repository.fetch(id: editingID)
                let unchanged = current.map { $0.type == type && Device.namesMatch($0.name, name) } ?? false
                if !unchanged, try await repository.contains(name: name, type: type) {
                    alertMessage = tr("You already have this device.")
                    return
                }
                var device = current ?? Device(name: name, type: type)
                device.name = name
                device.type = type
                try await repository.save(device)
                saved = device
            }, notFound: { router?.deviceForm(didFinish: .notFound) })
            if let saved { router?.deviceForm(didFinish: .saved(saved, editing: isEditing)) }
        }
    }

    func cancel() {
        router?.deviceForm(didFinish: .cancelled)
    }

    func delete() async {
        guard let id = editingID else { return }
        if await attempt({ try await repository.delete(id: id) }, notFound: { router?.deviceForm(didFinish: .notFound) }) {
            router?.deviceForm(didFinish: .deleted(id))
        }
    }
}
