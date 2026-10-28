import Domain
import WidgetsShared

/// Decorator that refreshes the widget snapshot after every write.
/// Features stay unaware of widgets; remove the wrapper in `AppContainer` to disable.
struct WidgetSyncingBrewRepository: BrewRepository {
    let wrapped: any BrewRepository
    let snapshotStore: WidgetSnapshotStore

    func fetchAll() async throws -> [Brew] {
        try await wrapped.fetchAll()
    }

    func fetch(id: Brew.ID) async throws -> Brew {
        try await wrapped.fetch(id: id)
    }

    func save(_ brew: Brew) async throws {
        try await wrapped.save(brew)
        await syncWidgets()
    }

    func delete(id: Brew.ID) async throws {
        try await wrapped.delete(id: id)
        await syncWidgets()
    }

    func changes() async -> AsyncStream<Void> {
        await wrapped.changes()
    }

    private func syncWidgets() async {
        guard let brews = try? await wrapped.fetchAll() else { return }
        snapshotStore.save(WidgetSnapshot(brews: brews))
    }
}
