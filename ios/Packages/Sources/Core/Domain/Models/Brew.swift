import Foundation

/// A recorded brew (alternative or espresso), made with the wizard or logged manually.
public struct Brew: Syncable {
    public let id: UUID
    public var legacyID: Int?
    /// When the brew happened.
    public var date: Date
    public var updatedAt: Date
    /// Set while the brew is in the trash.
    public var deletedAt: Date?

    public var method: BrewMethod
    public var bean: BeanReference?

    // Gear
    public var dripper: GearReference?
    public var grinder: GearReference?
    public var grindSetting: Int?
    public var filter: GearReference?
    public var isFilterRinsed: Bool?
    public var espressoMachine: GearReference?
    public var accessoryIDs: [UUID]
    public var aeropress: AeroPressOptions?

    // Recipe
    public var doseGrams: Double
    /// Water-to-coffee ratio, e.g. `16` for 1:16. For espresso: yield / dose.
    public var ratio: Double
    public var waterTemperature: Double?
    public var steps: [BrewStep]
    public var totalTime: TimeInterval?
    /// Explicit drink volume, used by manual entries. Otherwise see `volumeMilliliters`.
    public var beverageVolume: Double?
    public var espresso: EspressoShot?
    public var milk: MilkInfo?
    public var ice: IceInfo?

    // Tasting
    /// 0...10, one decimal.
    public var rating: Double
    public var flavors: [String]
    public var aromas: [String]
    public var notes: String

    public var origin: BrewOrigin
    /// Logged after the fact instead of brewed with the wizard.
    public var isManual: Bool
    public var isLiked: Bool

    public init(
        id: UUID = UUID(),
        legacyID: Int? = nil,
        date: Date = .now,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        method: BrewMethod,
        bean: BeanReference? = nil,
        dripper: GearReference? = nil,
        grinder: GearReference? = nil,
        grindSetting: Int? = nil,
        filter: GearReference? = nil,
        isFilterRinsed: Bool? = nil,
        espressoMachine: GearReference? = nil,
        accessoryIDs: [UUID] = [],
        aeropress: AeroPressOptions? = nil,
        doseGrams: Double,
        ratio: Double,
        waterTemperature: Double? = nil,
        steps: [BrewStep] = [],
        totalTime: TimeInterval? = nil,
        beverageVolume: Double? = nil,
        espresso: EspressoShot? = nil,
        milk: MilkInfo? = nil,
        ice: IceInfo? = nil,
        rating: Double,
        flavors: [String] = [],
        aromas: [String] = [],
        notes: String = "",
        origin: BrewOrigin = .home,
        isManual: Bool = false,
        isLiked: Bool = false
    ) {
        self.id = id
        self.legacyID = legacyID
        self.date = date
        self.updatedAt = updatedAt ?? date
        self.deletedAt = deletedAt
        self.method = method
        self.bean = bean
        self.dripper = dripper
        self.grinder = grinder
        self.grindSetting = grindSetting
        self.filter = filter
        self.isFilterRinsed = isFilterRinsed
        self.espressoMachine = espressoMachine
        self.accessoryIDs = accessoryIDs
        self.aeropress = aeropress
        self.doseGrams = doseGrams
        self.ratio = ratio
        self.waterTemperature = waterTemperature
        self.steps = steps
        self.totalTime = totalTime
        self.beverageVolume = beverageVolume
        self.espresso = espresso
        self.milk = milk
        self.ice = ice
        self.rating = Self.clampRating(rating)
        self.flavors = flavors
        self.aromas = aromas
        self.notes = notes
        self.origin = origin
        self.isManual = isManual
        self.isLiked = isLiked
    }
}

// MARK: - Derived values

public extension Brew {
    static let ratingRange: ClosedRange<Double> = 0...10

    var category: BrewCategory {
        espresso != nil ? .espresso : method.category
    }

    /// Planned water for alternative brews.
    var waterGrams: Double { doseGrams * ratio }

    /// Best estimate of the drink volume: explicit value → espresso yield → poured water → dose × ratio.
    var volumeMilliliters: Double {
        if let beverageVolume, beverageVolume > 0 { return beverageVolume }
        if let espresso { return espresso.yieldGrams }
        let poured = steps.totalPouredMilliliters
        return poured > 0 ? poured : waterGrams
    }

    var isCafeVisit: Bool {
        if case .cafe = origin { return true }
        return false
    }

    static func clampRating(_ value: Double) -> Double {
        (min(max(value, ratingRange.lowerBound), ratingRange.upperBound) * 10).rounded() / 10
    }
}

// MARK: - Supporting types

/// Snapshot of the bean used, linked to the inventory bag when it still exists.
/// The name is kept so the journal still reads correctly after the bag is deleted.
public struct BeanReference: Hashable, Codable, Sendable {
    public var beanID: UUID?
    public var name: String
    public var roaster: String
    public var roastProfile: RoastProfile?

    public init(beanID: UUID? = nil, name: String, roaster: String = "", roastProfile: RoastProfile? = nil) {
        self.beanID = beanID
        self.name = name
        self.roaster = roaster
        self.roastProfile = roastProfile
    }
}

/// Snapshot of a device or filter pack used, linked to the inventory when possible.
public struct GearReference: Hashable, Codable, Sendable {
    public var id: UUID?
    public var name: String

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct AeroPressOptions: Hashable, Codable, Sendable {
    public var isInverted: Bool
    public var filterCount: Int

    public init(isInverted: Bool = false, filterCount: Int = 1) {
        self.isInverted = isInverted
        self.filterCount = filterCount
    }
}

public enum BrewOrigin: Hashable, Codable, Sendable {
    case home
    /// A drink at a café; `place` may be empty.
    case cafe(place: String)
}
