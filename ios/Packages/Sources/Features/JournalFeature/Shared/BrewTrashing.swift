import Foundation
import Domain
import DesignSystem
import FactoryKit

/// Deletes a brew from the journal (web: `softDeleteBrew`): it goes to the trash, its coffee and
/// filter back to stock, and a toast offers Undo (which restores it, taking them again).
func trashBrew(id: Brew.ID) async throws {
    try await Container.shared.brewRepository().delete(id: id)
    let trash = Container.shared.trashRepository()
    let toasts = Container.shared.toasts()
    toasts.show(Toast(tr("Brew deleted"), style: .success, action: Toast.Action(tr("Undo")) {
        Task {
            do {
                try await trash.restore(brewID: id)
            } catch {
                toasts.show(error.localizedDescription, style: .error)
            }
        }
    }))
}
