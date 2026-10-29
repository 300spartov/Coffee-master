import CoreData
import Foundation
import Domain

/// How `upsert` treats a record that already exists.
enum UpsertPolicy: Sendable {
    /// Keep whichever version has the newer `updatedAt` (ties go to the incoming one).
    /// Used for imports and, later, sync.
    case lastWriteWins
    /// Always overwrite. Used for local edits.
    case overwrite
}

public struct UpsertResult: Equatable, Sendable {
    public var inserted = 0
    public var updated = 0
    /// Existing record was newer and kept.
    public var skipped = 0
    /// Identical to what's stored; nothing written (keeps re-imports and history quiet).
    public var unchanged = 0

    public init(inserted: Int = 0, updated: Int = 0, skipped: Int = 0, unchanged: Int = 0) {
        self.inserted = inserted
        self.updated = updated
        self.skipped = skipped
        self.unchanged = unchanged
    }
}

/// Generic CRUD for one syncable record type. Repositories are thin wrappers around this.
struct RecordStore<Record: StoredRecord>: Sendable {
    private typealias A = CoreDataModel.Attribute

    let persistence: PersistenceController

    // MARK: - Reads

    func fetch(id: UUID, _ filter: DeletedFilter = .exclude) async throws -> Record? {
        try await persistence.read { context in
            try Self.object(id: id, filter, in: context).map { try Record.read(from: $0) }
        }
    }

    /// Like `fetch`, but throws `RepositoryError.notFound` instead of returning `nil`.
    func require(id: UUID) async throws -> Record {
        guard let record = try await fetch(id: id) else { throw RepositoryError.notFound }
        return record
    }

    /// `filter` builds an extra predicate on the context's queue (`NSPredicate` isn't `Sendable`).
    func fetchAll(_ deleted: DeletedFilter = .exclude, where filter: (@Sendable () -> NSPredicate)? = nil) async throws -> [Record] {
        try await persistence.read { context in
            let predicates = [Self.predicate(for: deleted), filter?()].compactMap { $0 }
            let compound = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            return try Self.objects(in: context, predicate: compound, sort: Record.defaultSort).map { try Record.read(from: $0) }
        }
    }

    func count(_ deleted: DeletedFilter = .exclude) async throws -> Int {
        try await persistence.read { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: Record.entityName)
            request.predicate = Self.predicate(for: deleted)
            return try context.count(for: request)
        }
    }

    // MARK: - Writes

    /// A local edit: stamps `updatedAt` (so it wins in sync) and overwrites.
    func save(_ record: Record) async throws {
        var record = record
        record.touch()
        try await upsert([record], policy: .overwrite)
    }

    @discardableResult
    func upsert(_ records: [Record], policy: UpsertPolicy, author: PersistenceController.TransactionAuthor = .app) async throws -> UpsertResult {
        try await persistence.write(author: author) { context in
            try Self.upsert(records, policy: policy, in: context)
        }
    }

    /// Moves to the trash (`deletedAt`) and runs the record's soft-delete side effects in the same
    /// transaction. Throws `notFound` if missing or already trashed.
    func softDelete(id: UUID, at date: Date = .now) async throws {
        try await persistence.write { context in
            let deleted = try Self.mutate(id: id, in: context) { $0.markDeleted(at: date) }
            try Record.didSoftDelete(deleted, in: context)
        }
    }

    /// Brings a trashed record back, with its side effects. Throws `notFound` unless it's in the trash.
    func restore(id: UUID, at date: Date = .now) async throws {
        try await persistence.write { context in
            let restored = try Self.mutate(id: id, .only, in: context) { $0.restore(at: date) }
            try Record.didRestore(restored, in: context)
        }
    }

    /// Loads, changes and saves one active record in a single transaction.
    @discardableResult
    func mutate(id: UUID, _ change: @escaping @Sendable (inout Record) -> Void) async throws -> Record {
        try await persistence.write { context in
            try Self.mutate(id: id, in: context, change)
        }
    }

    /// Permanently removes one trashed record. Throws `notFound` if it isn't in the trash.
    func deletePermanently(id: UUID) async throws {
        try await persistence.write { context in
            guard let object = try Self.object(id: id, .only, in: context) else { throw RepositoryError.notFound }
            context.delete(object)
        }
    }

    /// Permanently removes trashed records deleted before `date` (trash TTL). Returns the count.
    @discardableResult
    func purgeDeleted(before date: Date) async throws -> Int {
        try await persistence.write { context in
            let predicate = NSPredicate(format: "%K != nil AND %K < %@", A.deletedAt, A.deletedAt, date as NSDate)
            let objects = try Self.objects(in: context, predicate: predicate)
            objects.forEach(context.delete)
            return objects.count
        }
    }

    func changes() -> AsyncStream<Void> {
        persistence.changes(of: Record.entityName)
    }

    // MARK: - Context-level helpers (shared with multi-entity transactions, e.g. import)

    static func upsert(_ records: [Record], policy: UpsertPolicy, in context: NSManagedObjectContext) throws -> UpsertResult {
        guard !records.isEmpty else { return UpsertResult() }
        let existing = try objects(in: context, predicate: NSPredicate(format: "%K IN %@", A.id, records.map(\.id)))
        var byID = [UUID: NSManagedObject]()
        for object in existing {
            if let id = object.value(forKey: A.id) as? UUID { byID[id] = object }
        }

        var result = UpsertResult()
        for record in records {
            let payload = try StoredRecordCoding.encode(record)
            if let object = byID[record.id] {
                let existingUpdatedAt = object.value(forKey: A.updatedAt) as? Date ?? .distantPast
                if policy == .lastWriteWins, existingUpdatedAt > record.updatedAt {
                    result.skipped += 1
                } else if object.value(forKey: A.payload) as? Data == payload {
                    result.unchanged += 1
                } else {
                    record.write(to: object, payload: payload)
                    result.updated += 1
                }
            } else {
                let object = NSManagedObject(entity: entity(in: context), insertInto: context)
                record.write(to: object, payload: payload)
                byID[record.id] = object
                result.inserted += 1
            }
        }
        return result
    }

    /// Context-level `mutate`, for multi-entity transactions. Throws `notFound` unless a record
    /// with `id` matches `filter`.
    @discardableResult
    static func mutate(
        id: UUID,
        _ filter: DeletedFilter = .exclude,
        in context: NSManagedObjectContext,
        _ change: (inout Record) -> Void
    ) throws -> Record {
        guard let object = try object(id: id, filter, in: context) else { throw RepositoryError.notFound }
        var record = try Record.read(from: object)
        change(&record)
        record.write(to: object, payload: try StoredRecordCoding.encode(record))
        return record
    }

    private static func entity(in context: NSManagedObjectContext) -> NSEntityDescription {
        NSEntityDescription.entity(forEntityName: Record.entityName, in: context)!
    }

    private static func object(id: UUID, _ filter: DeletedFilter, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let byID = NSPredicate(format: "%K == %@", A.id, id as CVarArg)
        let predicate = predicate(for: filter).map { NSCompoundPredicate(andPredicateWithSubpredicates: [byID, $0]) } ?? byID
        return try objects(in: context, predicate: predicate, limit: 1).first
    }

    private static func objects(
        in context: NSManagedObjectContext,
        predicate: NSPredicate?,
        sort: [SortKey] = [],
        limit: Int = 0
    ) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Record.entityName)
        request.predicate = predicate
        request.sortDescriptors = sort.map(\.descriptor)
        request.fetchLimit = limit
        request.returnsObjectsAsFaults = false
        return try context.fetch(request)
    }

    private static func predicate(for filter: DeletedFilter) -> NSPredicate? {
        switch filter {
        case .exclude: NSPredicate(format: "%K == nil", A.deletedAt)
        case .only: NSPredicate(format: "%K != nil", A.deletedAt)
        case .include: nil
        }
    }
}
