public extension RecordRepository {
    /// Calls `reload` now and again after every change, until the calling task is cancelled
    /// (bind it to a screen's lifetime with `.task`). Subscribes before the first load, so no change is missed.
    func observe(_ reload: @Sendable () async -> Void) async {
        let changes = await changes()
        await reload()
        for await _ in changes {
            await reload()
        }
    }
}
