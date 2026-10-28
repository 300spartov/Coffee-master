import CoreData

/// The Core Data model, defined in code (no `.xcdatamodeld`), so it lives in the package,
/// can be reviewed in diffs and is shared by the app and future extensions.
///
/// Storage design — "indexed columns + payload":
/// - every syncable entity stores the full Domain struct as JSON in `payload` (source of truth);
/// - a few **derived columns** (dates, ids, names, rating…) are written next to it for
///   predicates, sorting and statistics. They're rewritten on every save.
/// Adding a field to a Domain struct needs no model change; add a column only to query by it.
///
/// Migrations: when a column is added/changed, keep this version's builder, add a new one,
/// and bump `currentVersion`. Core Data infers lightweight migrations between the two.
enum CoreDataModel {
    static let currentVersion = 1

    /// One shared instance: several models describing the same entities confuse Core Data
    /// (e.g. several containers in tests).
    nonisolated(unsafe) static let shared: NSManagedObjectModel = makeV1()

    enum Entity {
        static let brew = "Brew"
        static let bean = "Bean"
        static let device = "Device"
        static let filterPack = "FilterPack"
        /// Singleton JSON documents: profile, achievements, suggestions.
        static let document = "UserDocument"
    }

    enum Attribute {
        // Shared by all syncable entities
        static let id = "id"
        static let legacyID = "legacyID"
        static let updatedAt = "updatedAt"
        static let deletedAt = "deletedAt"
        static let payload = "payload"
        // Brew
        static let date = "date"
        static let method = "method"
        static let category = "category"
        static let rating = "rating"
        static let beanID = "beanID"
        static let isManual = "isManual"
        static let isCafeVisit = "isCafeVisit"
        // Inventory
        static let name = "name"
        static let roaster = "roaster"
        static let remainingGrams = "remainingGrams"
        static let type = "type"
        static let remaining = "remaining"
        // Document
        static let key = "key"
    }

    // MARK: - Version 1

    private static func makeV1() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.versionIdentifiers = ["1"]
        model.entities = [
            syncableEntity(Entity.brew, columns: [
                attribute(Attribute.date, .dateAttributeType),
                attribute(Attribute.method, .stringAttributeType),
                attribute(Attribute.category, .stringAttributeType),
                attribute(Attribute.rating, .doubleAttributeType),
                attribute(Attribute.beanID, .UUIDAttributeType, optional: true),
                attribute(Attribute.isManual, .booleanAttributeType),
                attribute(Attribute.isCafeVisit, .booleanAttributeType),
            ], indexed: [Attribute.date, Attribute.beanID]),
            syncableEntity(Entity.bean, columns: [
                attribute(Attribute.name, .stringAttributeType),
                attribute(Attribute.roaster, .stringAttributeType),
                attribute(Attribute.remainingGrams, .doubleAttributeType),
            ], indexed: [Attribute.name]),
            syncableEntity(Entity.device, columns: [
                attribute(Attribute.name, .stringAttributeType),
                attribute(Attribute.type, .stringAttributeType),
            ], indexed: [Attribute.type]),
            syncableEntity(Entity.filterPack, columns: [
                attribute(Attribute.name, .stringAttributeType),
                attribute(Attribute.remaining, .integer64AttributeType),
            ], indexed: []),
            documentEntity(),
        ]
        return model
    }

    // MARK: - Builders

    private static func syncableEntity(_ name: String, columns: [NSAttributeDescription], indexed: [String]) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        let common = [
            attribute(Attribute.id, .UUIDAttributeType),
            attribute(Attribute.legacyID, .integer64AttributeType, optional: true),
            attribute(Attribute.updatedAt, .dateAttributeType),
            attribute(Attribute.deletedAt, .dateAttributeType, optional: true),
            attribute(Attribute.payload, .binaryDataAttributeType),
        ]
        entity.properties = common + columns
        entity.uniquenessConstraints = [[Attribute.id]]
        entity.indexes = ([Attribute.id, Attribute.updatedAt, Attribute.deletedAt] + indexed).map { index($0, in: entity) }
        return entity
    }

    private static func documentEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = Entity.document
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            attribute(Attribute.key, .stringAttributeType),
            attribute(Attribute.updatedAt, .dateAttributeType),
            attribute(Attribute.payload, .binaryDataAttributeType),
        ]
        entity.uniquenessConstraints = [[Attribute.key]]
        return entity
    }

    private static func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        if !optional {
            switch type {
            case .booleanAttributeType: attribute.defaultValue = false
            case .doubleAttributeType, .integer64AttributeType: attribute.defaultValue = 0
            case .stringAttributeType: attribute.defaultValue = ""
            default: break
            }
        }
        return attribute
    }

    private static func index(_ attributeName: String, in entity: NSEntityDescription) -> NSFetchIndexDescription {
        let property = entity.attributesByName[attributeName]!
        let element = NSFetchIndexElementDescription(property: property, collationType: .binary)
        return NSFetchIndexDescription(name: "by_\(attributeName)", elements: [element])
    }
}
