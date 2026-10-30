import Foundation
import Observation
import Domain
import FactoryKit

/// Add a device that isn't in the catalog, or rename / recategorize one you own.
@Observable
final class DeviceFormViewModel {
    enum Mode: Equatable {
        case add(DeviceType)
        case edit(Device.ID)
    }

    enum State: Equatable {
        case loading
        case ready
        case failed(String)
    }

    let mode: Mode
    var name = ""
    var type: DeviceType
    private(set) var state: State
    private(set) var isSaving = false
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

    var isEditing: Bool {
        if case .edit = mode { true } else { false }
    }

    var types: [DeviceType] { DeviceType.browsable }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedName.isEmpty }

    func load() async {
        guard case .edit(let id) = mode else { return }
        state = .loading
        do {
            let device = try await repository.fetch(id: id)
            name = device.name
            type = device.type
            state = .ready
        } catch RepositoryError.notFound {
            router?.deviceFormNotFound(id: id)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func save() async {
        guard isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            // Edit the record as it is now (not as it was when the sheet opened), so a device
            // removed or changed elsewhere meanwhile isn't brought back or overwritten.
            let current: Device?
            if case .edit(let id) = mode {
                current = try await repository.fetch(id: id)
            } else {
                current = nil
            }
            let unchanged = current.map { $0.type == type && Device.namesMatch($0.name, trimmedName) } ?? false
            if !unchanged, try await repository.contains(name: trimmedName, type: type) {
                alertMessage = tr("You already have this device.")
                return
            }
            var device = current ?? Device(name: trimmedName, type: type)
            device.name = trimmedName
            device.type = type
            try await repository.save(device)
            router?.deviceFormDidFinish(saved: device)
        } catch RepositoryError.notFound {
            if case .edit(let id) = mode { router?.deviceFormNotFound(id: id) }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func cancel() {
        router?.deviceFormDidFinish(saved: nil)
    }

    func delete() async {
        guard case .edit(let id) = mode else { return }
        do {
            try await repository.delete(id: id)
            router?.deviceFormDidDelete(id: id)
        } catch RepositoryError.notFound {
            router?.deviceFormNotFound(id: id)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
