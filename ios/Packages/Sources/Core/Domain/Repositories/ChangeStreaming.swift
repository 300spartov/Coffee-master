/// Anything that announces its writes (record repositories, the trash).
public protocol ChangeStreaming: Sendable {
    /// Emits after every write. The stream finishes when the consuming task is cancelled.
    func changes() async -> AsyncStream<Void>
}

public extension ChangeStreaming {
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

/// Like `ChangeStreaming.observe`, for a screen that shows several sources (e.g. devices and filter packs).
public func observe(_ sources: any ChangeStreaming..., reload: @escaping @Sendable () async -> Void) async {
    var streams: [AsyncStream<Void>] = []
    for source in sources { streams.append(await source.changes()) }
    await reload()
    await withTaskGroup(of: Void.self) { group in
        for stream in streams {
            group.addTask { for await _ in stream { await reload() } }
        }
    }
}
