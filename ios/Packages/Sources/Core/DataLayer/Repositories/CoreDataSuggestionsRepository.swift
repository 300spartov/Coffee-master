import Foundation
import Domain

public struct CoreDataSuggestionsRepository: SuggestionsRepository {
    private let documents: DocumentStore

    public init(persistence: PersistenceController) {
        documents = DocumentStore(persistence: persistence)
    }

    public func suggestions() async throws -> Suggestions {
        try await documents.load(Suggestions.self, key: .suggestions) ?? Suggestions()
    }

    public func remember(_ additions: Suggestions) async throws {
        try await documents.persistence.write { context in
            let current = try DocumentStore.load(Suggestions.self, key: .suggestions, in: context) ?? Suggestions()
            let merged = current.merging(additions)
            guard merged != current else { return }
            try DocumentStore.save(merged, key: .suggestions, updatedAt: .now, in: context)
        }
    }
}
