import Foundation
import Domain

/// In-memory store. Replace with a persistent implementation (SwiftData, Core Data, Supabase, …)
/// in `AppContainer` — features don't change.
public actor InMemoryBrewRepository: BrewRepository {
    private var storage: [Brew.ID: Brew]
    private var observers: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init(seed: [Brew] = Brew.samples) {
        storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

    public func fetchAll() async throws -> [Brew] {
        storage.values.sorted { $0.date > $1.date }
    }

    public func fetch(id: Brew.ID) async throws -> Brew {
        guard let brew = storage[id] else { throw RepositoryError.notFound }
        return brew
    }

    public func save(_ brew: Brew) async throws {
        storage[brew.id] = brew
        notifyObservers()
    }

    public func delete(id: Brew.ID) async throws {
        guard storage.removeValue(forKey: id) != nil else { throw RepositoryError.notFound }
        notifyObservers()
    }

    public func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        observers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(id) }
        }
        return stream
    }

    private func removeObserver(_ id: UUID) {
        observers[id] = nil
    }

    private func notifyObservers() {
        for continuation in observers.values {
            continuation.yield()
        }
    }
}
