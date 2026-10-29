import Foundation
import os

/// Fans "something changed" out to any number of `AsyncStream` subscribers. Thread-safe.
///
/// Backs every repository's `changes()`. Each stream buffers at most one pending event, so a slow
/// consumer reloads once rather than once per write. A stream ends when its consuming task is cancelled.
public final class ChangeBroadcaster: Sendable {
    private let continuations = OSAllocatedUnfairLock(initialState: [UUID: AsyncStream<Void>.Continuation]())

    public init() {}

    public func stream() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuations.withLock { $0[id] = continuation }
        continuation.onTermination = { [weak self] _ in
            self?.continuations.withLock { _ = $0.removeValue(forKey: id) }
        }
        return stream
    }

    public func notify() {
        continuations.withLock { Array($0.values) }.forEach { $0.yield() }
    }
}
