import Foundation
import Observation
import AppCore
import Domain
import DesignSystem
import FactoryKit

/// Deleted brews (web: "Видалені рецепти"): kept for `TrashPolicy.retention` (30 days), then purged at
/// launch. Restore brings a brew back (taking its coffee and filter again); delete removes it for good.
@Observable
final class TrashViewModel {
    private(set) var state: ListState<Brew> = .loading
    var alertMessage: String?

    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored @Injected(\.trashRepository) private var trash
    @ObservationIgnored @Injected(\.toasts) private var toasts

    init(clock: @escaping () -> Date = Date.init) {
        self.clock = clock
    }

    /// Bound to the view's lifetime via `.task`: loads, then reloads on every change.
    func start() async {
        await trash.observe { await self.load() }
    }

    func load() async {
        do {
            state = ListState(try await trash.trashedBrews())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Whole days until the brew is purged (at least 1 while it's still here).
    func daysLeft(_ brew: Brew) -> Int {
        guard let deletedAt = brew.deletedAt else { return 0 }
        let left = deletedAt.addingTimeInterval(TrashPolicy.retention).timeIntervalSince(clock())
        return max(Int((left / 86_400).rounded(.up)), 1)
    }

    func restore(_ brew: Brew) async {
        if await perform({ try await self.trash.restore(brewID: brew.id) }) {
            toasts.show(tr("Brew restored"), style: .success)
        }
    }

    func deletePermanently(_ brew: Brew) async {
        await perform { try await self.trash.deletePermanently(brewID: brew.id) }
    }

    func emptyTrash() async {
        await perform { try await self.trash.emptyTrash() }
    }

    /// The change stream reloads the list after a write; a failure keeps it as it is and alerts.
    @discardableResult
    private func perform(_ write: () async throws -> Void) async -> Bool {
        do {
            try await write()
            return true
        } catch {
            alertMessage = error.localizedDescription
            return false
        }
    }
}
