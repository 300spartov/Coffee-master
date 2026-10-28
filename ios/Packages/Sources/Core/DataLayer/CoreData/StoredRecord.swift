import CoreData
import Foundation
import Domain

/// Maps a Domain record to its Core Data row: full JSON payload + derived query columns.
protocol StoredRecord: Syncable {
    static var entityName: String { get }
    /// Default ordering for `fetchAll`.
    static var defaultSort: [SortKey] { get }
    /// Writes the derived columns (everything except id / legacyID / updatedAt / deletedAt / payload).
    func writeColumns(to object: NSManagedObject)
}

struct SortKey: Sendable {
    let key: String
    let ascending: Bool

    var descriptor: NSSortDescriptor { NSSortDescriptor(key: key, ascending: ascending) }
}

private typealias A = CoreDataModel.Attribute

extension StoredRecord {
    func write(to object: NSManagedObject, encoder: JSONEncoder) throws {
        object.setValue(id, forKey: A.id)
        object.setValue(legacyID.map { Int64($0) }, forKey: A.legacyID)
        object.setValue(updatedAt, forKey: A.updatedAt)
        object.setValue(deletedAt, forKey: A.deletedAt)
        object.setValue(try encoder.encode(self), forKey: A.payload)
        writeColumns(to: object)
    }

    static func read(from object: NSManagedObject, decoder: JSONDecoder) throws -> Self {
        guard let payload = object.value(forKey: A.payload) as? Data else {
            throw PersistenceError.corruptRecord(entity: entityName)
        }
        return try decoder.decode(Self.self, from: payload)
    }
}

enum StoredRecordCoding {
    /// Sorted keys make payloads byte-stable, so "unchanged" can be detected by comparing bytes.
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

public enum PersistenceError: Error, Equatable {
    case corruptRecord(entity: String)
}

// MARK: - Records

extension Brew: StoredRecord {
    static let entityName = CoreDataModel.Entity.brew
    static let defaultSort = [SortKey(key: A.date, ascending: false)]

    func writeColumns(to object: NSManagedObject) {
        object.setValue(date, forKey: A.date)
        object.setValue(method.rawValue, forKey: A.method)
        object.setValue(category.rawValue, forKey: A.category)
        object.setValue(rating, forKey: A.rating)
        object.setValue(bean?.beanID, forKey: A.beanID)
        object.setValue(isManual, forKey: A.isManual)
        object.setValue(isCafeVisit, forKey: A.isCafeVisit)
    }
}

extension Bean: StoredRecord {
    static let entityName = CoreDataModel.Entity.bean
    static let defaultSort = [SortKey(key: A.updatedAt, ascending: false)]

    func writeColumns(to object: NSManagedObject) {
        object.setValue(name, forKey: A.name)
        object.setValue(roaster, forKey: A.roaster)
        object.setValue(remainingGrams, forKey: A.remainingGrams)
    }
}

extension Device: StoredRecord {
    static let entityName = CoreDataModel.Entity.device
    static let defaultSort = [SortKey(key: A.type, ascending: true), SortKey(key: A.name, ascending: true)]

    func writeColumns(to object: NSManagedObject) {
        object.setValue(name, forKey: A.name)
        object.setValue(type.rawValue, forKey: A.type)
    }
}

extension FilterPack: StoredRecord {
    static let entityName = CoreDataModel.Entity.filterPack
    static let defaultSort = [SortKey(key: A.updatedAt, ascending: false)]

    func writeColumns(to object: NSManagedObject) {
        object.setValue(name, forKey: A.name)
        object.setValue(Int64(remaining), forKey: A.remaining)
    }
}
