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

    /// Corrects one pour (index into the steps); other steps are left alone.
    mutating func setPour(at index: Int, milliliters: Double) {
        guard indices.contains(index), self[index].isPour else { return }
        self[index].kind = .pour(milliliters: Swift.max(milliliters, 0))
    }

    /// The steps one after another from the first one's start, in their order (after editing).
    func resequenced() -> [BrewStep] {
        var start = first?.start ?? 0
        return map { step in
            var step = step
            step.start = start
            step.duration = Swift.max(step.duration, 0)
            start = step.end
            return step
        }
    }

    /// Spreads `total` ml evenly over the pours (to 0.1 ml, like the web app).
    mutating func spreadPours(_ total: Double) {
        let pours = indices.filter { self[$0].isPour }
        guard !pours.isEmpty else { return }
        let each = (Swift.max(total, 0) / Double(pours.count) * 10).rounded() / 10
        pours.forEach { self[$0].kind = .pour(milliliters: each) }
    }
}

public extension Sequence where Element == BrewStep {
    /// Each pour's ml, in order.
    var pours: [Double] { compactMap(\.pourMilliliters) }
}
