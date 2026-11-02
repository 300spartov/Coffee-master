import Foundation
import AppCore

/// How an add / edit form ended, reported to its router in one call.
public enum FormResult<Item: Identifiable> {
    case added(Item)
    case updated(Item)
    case deleted(Item.ID)
    case cancelled
    /// The record is gone (deleted elsewhere, a stale link).
    case notFound

    /// `.updated` when an existing record was edited, `.added` for a new one.
    public static func saved(_ item: Item, editing: Bool) -> Self {
        editing ? .updated(item) : .added(item)
    }
}

public extension RecordRepository {
    /// The record being edited as it is now, or `nil` for a new one (so a form saves over the latest
    /// copy and never brings back one removed elsewhere: that throws `notFound`).
    func fetch(id: Record.ID?) async throws -> Record? {
        guard let id else { return nil }
        return try await fetch(id: id)
    }
}

public extension AlertingViewModel {
    /// Like `attempt`, but a missing record calls `notFound` instead of showing an alert.
    @discardableResult
    func attempt(_ work: () async throws -> Void, notFound: () -> Void) async -> Bool {
        do {
            try await work()
            return true
        } catch RepositoryError.notFound {
            notFound()
            return false
        } catch {
            alertMessage = error.localizedDescription
            return false
        }
    }
}
