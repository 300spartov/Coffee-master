import Foundation

/// How a brew was made.
///
/// Open set: the web app stores methods as free text ("V60", "Ice Latte", "Інше", …), so this is a
/// string-backed value with well-known presets rather than a closed enum. Unknown names are preserved.
public struct BrewMethod: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Presets (names match the web app so imported data maps onto them)

public extension BrewMethod {
    // Alternative
    static let v60: BrewMethod = "V60"
    static let aeropress: BrewMethod = "Aeropress"
    static let chemex: BrewMethod = "Chemex"
    static let frenchPress: BrewMethod = "French Press"
    static let drip: BrewMethod = "Drip"
    static let coldBrew: BrewMethod = "Cold Brew"
    static let batchBrewing: BrewMethod = "Batch Brewing"
    static let origami: BrewMethod = "Origami"
    static let flower: BrewMethod = "Flower"
    static let moka: BrewMethod = "Moka"

    // Espresso-based
    static let espresso: BrewMethod = "Espresso"
    static let cappuccino: BrewMethod = "Cappuccino"
    static let flatWhite: BrewMethod = "Flat White"
    static let latte: BrewMethod = "Latte"
    static let bumble: BrewMethod = "Bumble"
    static let espressoTonic: BrewMethod = "Espresso Tonic"

    /// Choices in the brew wizard's "Alternative" picker.
    static let alternativePresets: [BrewMethod] = [.v60, .aeropress, .chemex, .frenchPress, .drip, .coldBrew, .batchBrewing]
    /// Choices in the brew wizard's "Espresso" picker.
    static let espressoPresets: [BrewMethod] = [.espresso, .cappuccino, .flatWhite, .latte, .bumble, .espressoTonic]
}

// MARK: - Category

public enum BrewCategory: String, Codable, Sendable, CaseIterable {
    /// Pour-over and drip.
    case filter
    /// Espresso and espresso-based drinks.
    case espresso
    /// Immersion and pressure brewers (AeroPress, French Press, Moka, …). The web app calls this "other".
    case immersion
}

public extension BrewMethod {
    var category: BrewCategory {
        let name = rawValue.lowercased()
        if Self.espressoKeywords.contains(where: name.contains) { return .espresso }
        if Self.immersionKeywords.contains(where: name.contains) { return .immersion }
        return .filter
    }

    var isEspressoBased: Bool { category == .espresso }

    // The web app's `methodCat` only matched "espres"; milk drinks are espresso-based too.
    private static let espressoKeywords = [
        "espres", "еспрес", "эспрес", "cappuccino", "капучино", "latte", "латте", "flat white",
        "cortado", "кортадо", "ristretto", "ристрето", "bumble", "бамбл", "long black", "americano", "американо",
    ]
    private static let immersionKeywords = [
        "aero", "аеро", "аэро", "french", "френч", "пресс", "moka", "мока", "гейзер", "турка", "cold brew", "clever", "siphon", "сифон",
    ]
}
