import Foundation

// Numbers, amounts and times as every screen shows them. Pure formatting, so `nonisolated`: usable
// from value types and background work, not only from views.

/// "2:05" from seconds (whole seconds gone, like a stopwatch).
nonisolated public func clockText(_ seconds: TimeInterval) -> String {
    Duration.seconds(seconds.rounded(.down)).formatted(.time(pattern: .minuteSecond))
}

/// "12 s", counted like the clocks (whole seconds gone).
nonisolated public func secondsText(_ value: TimeInterval) -> String {
    let seconds = Int(value.rounded(.down))
    return tr("\(seconds) s")
}

/// A number with up to one decimal: "16", "15.5".
nonisolated public func decimal(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...1)))
}

/// "256 ml".
nonisolated public func millilitersText(_ value: Double) -> String {
    "\(decimal(value)) \(tr("ml"))"
}

/// "16 g".
nonisolated public func gramsText(_ value: Double) -> String {
    "\(decimal(value)) g"
}

/// "93 °C".
nonisolated public func celsiusText(_ value: Double) -> String {
    "\(decimal(value)) °C"
}

/// "8.5": a 0–10 rating, one decimal.
nonisolated public func ratingText(_ rating: Double) -> String {
    rating.formatted(.number.precision(.fractionLength(1)))
}
