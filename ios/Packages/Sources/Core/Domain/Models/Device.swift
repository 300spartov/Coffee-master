import Foundation

/// A piece of equipment the user owns (from the built-in catalog or added manually).
public struct Device: Syncable {
    public let id: UUID
    public var legacyID: Int?
    public var updatedAt: Date
    public var deletedAt: Date?

    public var name: String
    public var type: DeviceType

    public init(
        id: UUID = UUID(),
        legacyID: Int? = nil,
        updatedAt: Date = .now,
        deletedAt: Date? = nil,
        name: String,
        type: DeviceType
    ) {
        self.id = id
        self.legacyID = legacyID
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.name = name
        self.type = type
    }
}

public extension Device {
    /// Whether two device names refer to the same device: ignores case, accents and surrounding
    /// spaces ("mahlkonig x54 " matches "Mahlkönig X54"). Used for duplicate checks everywhere.
    static func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines)
            .compare(rhs.trimmingCharacters(in: .whitespacesAndNewlines), options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }
}

/// Raw values match the web app (`acc` for accessories).
public enum DeviceType: String, Codable, Sendable, CaseIterable {
    case dripper
    case espressoMachine = "espresso"
    case grinder
    case kettle
    case filter
    case accessory = "acc"
}

/// A pack of paper filters with a remaining count.
public struct FilterPack: Syncable {
    public let id: UUID
    public var legacyID: Int?
    public var updatedAt: Date
    public var deletedAt: Date?

    public var name: String
    public var total: Int
    public var remaining: Int

    public init(
        id: UUID = UUID(),
        legacyID: Int? = nil,
        updatedAt: Date = .now,
        deletedAt: Date? = nil,
        name: String,
        total: Int = FilterPack.defaultCount,
        remaining: Int? = nil
    ) {
        self.id = id
        self.legacyID = legacyID
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.name = name
        self.total = max(total, 0)
        self.remaining = min(max(remaining ?? total, 0), max(total, 0))
    }
}

public extension FilterPack {
    static let defaultCount = 100
    /// The web app warns at 10 or fewer.
    static let lowStockThreshold = 10

    var isEmpty: Bool { remaining <= 0 }
    var isLow: Bool { remaining <= Self.lowStockThreshold }

    mutating func use(count: Int = 1, at date: Date = .now) {
        remaining = max(0, remaining - max(count, 0))
        touch(at: date)
    }

    mutating func putBack(count: Int = 1, at date: Date = .now) {
        remaining = min(total, remaining + max(count, 0))
        touch(at: date)
    }
}
