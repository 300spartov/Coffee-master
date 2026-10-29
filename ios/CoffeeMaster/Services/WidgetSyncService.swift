import Foundation
import AppCore
import Domain
import FactoryKit
import WidgetsShared

/// Keeps the widget snapshot in step with the brews. It listens to the repository's change stream,
/// so every write path is covered (saves, deletes, trash restore and purge, web import).
final class WidgetSyncService {
    @Injected(\.brewRepository) private var brews
    private let snapshotStore = WidgetSnapshotStore()
    private var task: Task<Void, Never>?

    func start() {
        guard task == nil else { return }
        task = Task { [brews, snapshotStore] in
            let changes = await brews.changes()
            await Self.sync(brews, to: snapshotStore)
            for await _ in changes {
                await Self.sync(brews, to: snapshotStore)
            }
        }
    }

    private nonisolated static func sync(_ brews: any BrewRepository, to store: WidgetSnapshotStore) async {
        do {
            store.save(WidgetSnapshot(brews: try await brews.fetchAll()))
        } catch {
            Log.widgets.error("Widget sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
