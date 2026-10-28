import Foundation

/// One recorded step of an alternative brew: a pour, a pause or an action (stir, swirl, …).
public struct BrewStep: Hashable, Codable, Sendable {
    public enum Kind: Hashable, Codable, Sendable {
        case pour(milliliters: Double)
        case pause
        case action(BrewAction)
    }

    public var kind: Kind
    /// Offset from the start of the brew.
    public var start: TimeInterval
    public var duration: TimeInterval

    public init(kind: Kind, start: TimeInterval, duration: TimeInterval) {
        self.kind = kind
        self.start = start
        self.duration = duration
    }

    public var end: TimeInterval { start + duration }

    public var pouredMilliliters: Double {
        if case .pour(let milliliters) = kind { return milliliters }
        return 0
    }
}

/// Open set of in-brew actions; unknown labels from imported data are preserved.
public struct BrewAction: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }

    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let stir: BrewAction = "stir"
    public static let swirl: BrewAction = "swirl"
    public static let shake: BrewAction = "shake"
    /// AeroPress plunge.
    public static let press: BrewAction = "press"
}

public extension Array where Element == BrewStep {
    var totalPouredMilliliters: Double {
        reduce(0) { $0 + $1.pouredMilliliters }
    }

    var pourCount: Int {
        filter { $0.pouredMilliliters > 0 }.count
    }
}
