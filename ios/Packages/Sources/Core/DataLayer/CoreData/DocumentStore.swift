import CoreData
import Foundation
import Domain

/// Singleton values stored as JSON documents: profile, earned achievements, autocomplete suggestions.
struct DocumentStore: Sendable {
    enum Key: String, Sendable {
        case profile
        case achievements
        case suggestions
    }

    private typealias A = CoreDataModel.Attribute

    let persistence: PersistenceController

    func load<Value: Codable & Sendable>(_ type: Value.Type, key: Key) async throws -> Value? {
        try await persistence.read { context in
            try Self.load(type, key: key, in: context)
        }
    }

    func save<Value: Codable & Sendable>(_ value: Value, key: Key, updatedAt: Date = .now) async throws {
        try await persistence.write { context in
            try Self.save(value, key: key, updatedAt: updatedAt, in: context)
        }
    }

    func changes() -> AsyncStream<Void> {
        persistence.changes(of: CoreDataModel.Entity.document)
    }

    // MARK: - Context-level helpers

    static func load<Value: Decodable>(_ type: Value.Type, key: Key, in context: NSManagedObjectContext) throws -> Value? {
        guard let payload = try object(key: key, in: context)?.value(forKey: A.payload) as? Data else { return nil }
        return try StoredRecordCoding.decode(type, from: payload)
    }

    static func save<Value: Encodable>(_ value: Value, key: Key, updatedAt: Date, in context: NSManagedObjectContext) throws {
        let object = try object(key: key, in: context) ?? {
            let entity = NSEntityDescription.entity(forEntityName: CoreDataModel.Entity.document, in: context)!
            let object = NSManagedObject(entity: entity, insertInto: context)
            object.setValue(key.rawValue, forKey: A.key)
            return object
        }()
        object.setValue(try StoredRecordCoding.encode(value), forKey: A.payload)
        object.setValue(updatedAt, forKey: A.updatedAt)
    }

    private static func object(key: Key, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataModel.Entity.document)
        request.predicate = NSPredicate(format: "%K == %@", A.key, key.rawValue)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
