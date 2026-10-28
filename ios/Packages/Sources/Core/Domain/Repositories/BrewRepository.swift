import Foundation

/// Abstraction over brew storage. Features depend on this protocol only;
/// concrete implementations live in `DataLayer` and are chosen in the app's composition root.
public protocol BrewRepository: Sendable {
    func fetchAll() async throws -> [Brew]
    func fetch(id: Brew.ID) async throws -> Brew
    func save(_ brew: Brew) async throws
    func delete(id: Brew.ID) async throws
    /// Emits after every write. The stream finishes when the consuming task is cancelled.
    func changes() async -> AsyncStream<Void>
}

public enum RepositoryError: Error, Equatable {
    case notFound
}
