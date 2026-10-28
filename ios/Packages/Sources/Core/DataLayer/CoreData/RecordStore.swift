import CoreData
import Foundation
import Domain

/// How `upsert` treats a record that already exists.
public enum UpsertPolicy: Sendable {
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

    public var total: Int { inserted + updated + skipped + unchanged }
}

/// Generic CRUD for one syncable record type. Repositories are thin wrappers around this.
struct RecordStore<Record: StoredRecord>: Sendable {
    private typealias A = CoreDataModel.Attribute

    let persistence: PersistenceController

    // MARK: - Reads

    func fetch(id: UUID, includeDeleted: Bool = false) async throws -> Record? {
        try await persistence.read { context in
            try Self.objects(in: context, predicate: Self.predicate(id: id, includeDeleted: includeDeleted), limit: 1)
                .first
                .map { try Record.read(from: $0, decoder: JSONDecoder()) }
        }
    }

    /// `deleted`: `.exclude` for normal lists, `.only` for the trash.
    /// `filter` builds an extra predicate on the context's queue (`NSPredicate` isn't `Sendable`).
    func fetchAll(deleted: DeletedFilter = .exclude, where filter: (@Sendable () -> NSPredicate)? = nil) async throws -> [Record] {
        let format = deleted.predicateFormat
        return try await persistence.read { context in
            var predicates = [NSPredicate]()
            if let format { predicates.append(NSPredicate(format: format)) }
            if let filter { predicates.append(filter()) }
            let compound = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let decoder = JSONDecoder()
            return try Self.objects(in: context, predicate: compound, sort: Record.defaultSort).map {
                try Record.read(from: $0, decoder: decoder)
            }
        }
    }

    func count(deleted: DeletedFilter = .exclude) async throws -> Int {
        let format = deleted.predicateFormat
        return try await persistence.read { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: Record.entityName)
            request.predicate = format.map { NSPredicate(format: $0) }
            return try context.count(for: request)
        }
    }

    // MARK: - Writes

    @discardableResult
    func upsert(_ records: [Record], policy: UpsertPolicy, author: PersistenceController.TransactionAuthor = .app) async throws -> UpsertResult {
        try await persistence.write(author: author) { context in
            try Self.upsert(records, policy: policy, in: context)
        }
    }

    /// Moves to the trash (`deletedAt`). Throws `notFound` if missing or already deleted.
    func softDelete(id: UUID, at date: Date = .now) async throws {
        try await mutate(id: id, includeDeleted: false) { $0.markDeleted(at: date) }
    }

    func restore(id: UUID, at date: Date = .now) async throws {
        try await mutate(id: id, includeDeleted: true) { $0.restore(at: date) }
    }

    /// Loads, changes and saves one record in a single transaction.
    @discardableResult
    func mutate(id: UUID, includeDeleted: Bool = false, _ change: @escaping @Sendable (inout Record) -> Void) async throws -> Record {
        try await persistence.write { context in
            guard let object = try Self.objects(in: context, predicate: Self.predicate(id: id, includeDeleted: includeDeleted), limit: 1).first else {
                throw RepositoryError.notFound
            }
            var record = try Record.read(from: object, decoder: JSONDecoder())
            change(&record)
            try record.write(to: object, encoder: StoredRecordCoding.encoder())
            return record
        }
    }

    /// Permanently removes trashed records deleted before `date` (trash TTL). Returns the count.
    @discardableResult
    func purgeDeleted(before date: Date) async throws -> Int {
        try await persistence.write { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: Record.entityName)
            request.predicate = NSPredicate(format: "%K != nil AND %K < %@", A.deletedAt, A.deletedAt, date as NSDate)
            let objects = try context.fetch(request)
            objects.forEach(context.delete)
            return objects.count
        }
    }

    func changes() -> AsyncStream<Void> {
        persistence.changes(of: [Record.entityName])
    }

    // MARK: - Context-level helpers (shared with multi-entity transactions, e.g. import)

    static func upsert(_ records: [Record], policy: UpsertPolicy, in context: NSManagedObjectContext) throws -> UpsertResult {
        guard !records.isEmpty else { return UpsertResult() }
        let existing = try objects(in: context, predicate: NSPredicate(format: "%K IN %@", A.id, records.map(\.id)))
        var byID = [UUID: NSManagedObject]()
        for object in existing {
            if let id = object.value(forKey: A.id) as? UUID { byID[id] = object }
        }

        let encoder = StoredRecordCoding.encoder()
        var result = UpsertResult()
        for record in records {
            if let object = byID[record.id] {
                let existingUpdatedAt = object.value(forKey: A.updatedAt) as? Date ?? .distantPast
                if policy == .lastWriteWins, existingUpdatedAt > record.updatedAt {
                    result.skipped += 1
                    continue
                }
                if object.value(forKey: A.payload) as? Data == (try encoder.encode(record)) {
                    result.unchanged += 1
                    continue
                }
                try record.write(to: object, encoder: encoder)
                result.updated += 1
            } else {
                let object = NSManagedObject(entity: entity(in: context), insertInto: context)
                try record.write(to: object, encoder: encoder)
                byID[record.id] = object
                result.inserted += 1
            }
        }
        return result
    }

    private static func entity(in context: NSManagedObjectContext) -> NSEntityDescription {
        NSEntityDescription.entity(forEntityName: Record.entityName, in: context)!
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

    private static func predicate(id: UUID, includeDeleted: Bool) -> NSPredicate {
        includeDeleted
            ? NSPredicate(format: "%K == %@", A.id, id as CVarArg)
            : NSPredicate(format: "%K == %@ AND %K == nil", A.id, id as CVarArg, A.deletedAt)
    }
}

enum DeletedFilter: Sendable {
    case exclude
    case only
    case include

    var predicateFormat: String? {
        switch self {
        case .exclude: "\(CoreDataModel.Attribute.deletedAt) == nil"
        case .only: "\(CoreDataModel.Attribute.deletedAt) != nil"
        case .include: nil
        }
    }
}

extension UpsertPolicy: Equatable {}
