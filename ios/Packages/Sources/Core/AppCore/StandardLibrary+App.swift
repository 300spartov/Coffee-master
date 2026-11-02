import Foundation

public extension Comparable {
    /// The value kept within `range`.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

public extension Double {
    /// Rounded to one decimal (ratios, ratings, ml).
    var roundedToTenth: Double { (self * 10).rounded() / 10 }
}

public extension String {
    /// Without leading and trailing whitespace and newlines (what forms save).
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

/// Something with a stock that runs out: a bag of beans, a pack of filters.
public protocol Stocked {
    var isEmpty: Bool { get }
    /// Running low, or empty (each item has its own rule).
    var isLow: Bool { get }
    /// 0...1, for progress bars.
    var remainingFraction: Double { get }
}
