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

    /// The pour's ml, or nil for pauses and actions.
    public var pourMilliliters: Double? {
        if case .pour(let milliliters) = kind { milliliters } else { nil }
    }

    public var isPour: Bool { pourMilliliters != nil }

    public var pouredMilliliters: Double { pourMilliliters ?? 0 }
}

/// Open set of in-brew actions; unknown labels from imported data are preserved.
public struct BrewAction: StringBacked {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }

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

public extension Sequence where Element == BrewStep {
    /// Each pour's ml, in order.
    var pours: [Double] { compactMap(\.pourMilliliters) }
}
