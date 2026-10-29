import Foundation

/// A bag of coffee in the inventory.
public struct Bean: Syncable {
    public let id: UUID
    public var legacyID: Int?
    public var updatedAt: Date
    public var deletedAt: Date?

    public var name: String
    public var roaster: String
    public var totalGrams: Double
    public var remainingGrams: Double
    public var country: String
    public var farm: String
    public var process: ProcessingMethod?
    /// 0...100 cupping score.
    public var score: Double?
    /// Free-text tasting descriptors from the bag.
    public var descriptors: String
    /// `nil` = derive from the brew method.
    public var roastProfile: RoastProfile?

    public init(
        id: UUID = UUID(),
        legacyID: Int? = nil,
        updatedAt: Date = .now,
        deletedAt: Date? = nil,
        name: String,
        roaster: String = "",
        totalGrams: Double = Bean.defaultBagGrams,
        remainingGrams: Double? = nil,
        country: String = "",
        farm: String = "",
        process: ProcessingMethod? = nil,
        score: Double? = nil,
        descriptors: String = "",
        roastProfile: RoastProfile? = nil
    ) {
        self.id = id
        self.legacyID = legacyID
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.name = name
        self.roaster = roaster
        self.totalGrams = max(totalGrams, 0)
        self.remainingGrams = min(max(remainingGrams ?? totalGrams, 0), self.totalGrams)
        self.country = country
        self.farm = farm
        self.process = process
        self.score = score
        self.descriptors = descriptors
        self.roastProfile = roastProfile
    }
}

public extension Bean {
    static let defaultBagGrams: Double = 250

    var isEmpty: Bool { remainingGrams <= 0 }

    /// 0...1, for progress bars.
    var remainingFraction: Double {
        totalGrams > 0 ? min(max(remainingGrams / totalGrams, 0), 1) : 0
    }

    /// Takes coffee out of the bag (a brew was saved). Never goes below zero.
    mutating func consume(grams: Double, at date: Date = .now) {
        remainingGrams = max(0, remainingGrams - max(grams, 0))
        touch(at: date)
    }

    /// Puts coffee back (a brew was deleted). Never exceeds the bag size.
    mutating func restock(grams: Double, at date: Date = .now) {
        remainingGrams = min(totalGrams, remainingGrams + max(grams, 0))
        touch(at: date)
    }

    /// Changes the bag size, keeping the amount already used.
    mutating func resize(totalGrams newTotal: Double, at date: Date = .now) {
        let used = totalGrams - remainingGrams
        totalGrams = max(newTotal, 0)
        remainingGrams = max(0, totalGrams - used)
        touch(at: date)
    }
}

public enum RoastProfile: String, Codable, Sendable, CaseIterable {
    case filter
    case espresso
    case omni
}

/// Open set; presets match the web app's bean form.
public struct ProcessingMethod: StringBacked {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }

    public static let washed: ProcessingMethod = "Washed"
    public static let natural: ProcessingMethod = "Natural"
    public static let honey: ProcessingMethod = "Honey"
    public static let anaerobic: ProcessingMethod = "Anaerobic"
    public static let carbonicMaceration: ProcessingMethod = "Carbonic Maceration"
    public static let wetHulled: ProcessingMethod = "Wet-Hulled"

    public static let presets: [ProcessingMethod] = [.washed, .natural, .honey, .anaerobic, .carbonicMaceration, .wetHulled]
}
