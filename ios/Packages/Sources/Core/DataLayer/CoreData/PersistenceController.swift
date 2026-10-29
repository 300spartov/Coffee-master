import CoreData
import Foundation
import Domain
import AppCore

/// Owns the Core Data stack. All reads and writes run on short-lived background contexts,
/// so callers only ever see Domain structs and no managed object crosses threads.
///
/// - Store file lives in the App Group container (so a widget extension can open it), falling back
///   to Application Support when the entitlement isn't configured (simulator, tests, previews).
/// - Persistent history tracking is on: every transaction is tagged with a `TransactionAuthor`;
///   the sync engine (Phase 5) will read history to build its outbox.
public final class PersistenceController: @unchecked Sendable {
    // @unchecked: `NSPersistentContainer` is safe to share for `newBackgroundContext()`;
    // all mutable state below is behind a lock.

    public enum Location: Sendable {
        /// App Group container if available, otherwise Application Support.
        case appGroup(String)
        case directory(URL)
        /// SQLite at `/dev/null`: in-memory, but with history tracking (tests, previews).
        case inMemory
    }

    /// Who made a change. Lets sync skip its own writes and lets us tell imports apart.
    public enum TransactionAuthor: String, Sendable {
        case app
        case `import`
        case sync
        case widget
    }

    private static let storeFileName = "CoffeeMaster.sqlite"

    let container: NSPersistentContainer
    private let storeURL: URL
    /// One broadcaster per entity, so observers only hear about the entity they watch.
    private let broadcasters: [String: ChangeBroadcaster] = Dictionary(
        uniqueKeysWithValues: CoreDataModel.shared.entities.compactMap(\.name).map { ($0, ChangeBroadcaster()) }
    )

    public init(location: Location = .appGroup(AppConfiguration.appGroupID)) throws {
        storeURL = Self.storeURL(for: location)
        container = NSPersistentContainer(name: "CoffeeMaster", managedObjectModel: CoreDataModel.shared)

        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError {
            Log.data.error("Failed to load store at \(self.storeURL.path, privacy: .public): \(loadError.localizedDescription, privacy: .public)")
            throw loadError
        }
        Log.data.info("Store loaded at \(self.storeURL.path, privacy: .public)")
    }

    // MARK: - Access

    /// Runs `block` on a fresh background context and saves if anything changed.
    /// Observers of the touched entities are notified after a successful save.
    func write<T: Sendable>(
        author: TransactionAuthor = .app,
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = makeContext(author: author)
        let (result, changed) = try await context.perform {
            let result = try block(context)
            let changed = Self.changedEntities(in: context)
            if context.hasChanges {
                try context.save()
            }
            return (result, changed)
        }
        if !changed.isEmpty {
            changed.forEach { broadcasters[$0]?.notify() }
        }
        return result
    }

    func read<T: Sendable>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = makeContext(author: .app)
        return try await context.perform { try block(context) }
    }

    /// Emits after every saved write that touched `entity`.
    func changes(of entity: String) -> AsyncStream<Void> {
        guard let broadcaster = broadcasters[entity] else { preconditionFailure("Unknown entity \(entity)") }
        return broadcaster.stream()
    }

    // MARK: - Private

    private func makeContext(author: TransactionAuthor) -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.transactionAuthor = author.rawValue
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        return context
    }

    private static func changedEntities(in context: NSManagedObjectContext) -> Set<String> {
        let objects = context.insertedObjects.union(context.updatedObjects).union(context.deletedObjects)
        return Set(objects.compactMap { $0.entity.name })
    }

    private static func storeURL(for location: Location) -> URL {
        switch location {
        case .inMemory:
            return URL(fileURLWithPath: "/dev/null")
        case .directory(let directory):
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory.appendingPathComponent(storeFileName)
        case .appGroup(let identifier):
            if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
                return storeURL(for: .directory(groupURL.appendingPathComponent("Database", isDirectory: true)))
            }
            Log.data.notice("App Group \(identifier, privacy: .public) unavailable, using Application Support")
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            return storeURL(for: .directory(support.appendingPathComponent("Database", isDirectory: true)))
        }
    }
}
