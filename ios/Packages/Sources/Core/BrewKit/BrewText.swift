import Foundation
import Domain

// Brew numbers and labels as the brew wizard and the journal show them. Pure formatting, so
// `nonisolated`: usable from value types and background work, not only from views.

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

/// "1:2.0", "1:16.5": a brew ratio with one decimal.
nonisolated public func ratioText(_ ratio: Double) -> String {
    "1:\(ratio.formatted(.number.precision(.fractionLength(1))))"
}

/// "Bloom" for the first pour, then "Pour 2", "Pour 3", ….
nonisolated public func pourTitle(_ number: Int) -> String {
    number == 1 ? tr("Bloom") : tr("Pour \(number)")
}

nonisolated public extension BrewAction {
    var title: String {
        switch self {
        case .stir: tr("Stir")
        case .swirl: tr("Swirl")
        case .shake: tr("Shake")
        case .press: tr("Press")
        default: rawValue
        }
    }

    var systemImage: String {
        switch self {
        case .stir: "arrow.clockwise"
        case .swirl: "arrow.triangle.2.circlepath"
        case .shake: "waveform.path"
        case .press: "arrow.down.circle.fill"
        default: "bolt"
        }
    }
}

nonisolated public extension BrewMethod {
    /// The method's icon (the web's per-method icons, in SF Symbols).
    var systemImage: String {
        switch self {
        case .v60: "line.3.horizontal.decrease"
        case .aeropress: "cylinder"
        case .chemex: "flask"
        case .frenchPress: "cylinder.split.1x2"
        case .drip: "drop"
        case .coldBrew: "snowflake"
        case .batchBrewing: "mug"
        case .espresso: "cup.and.saucer.fill"
        case .cappuccino: "cup.and.saucer"
        case .flatWhite: "cup.and.heat.waves"
        case .latte: "mug.fill"
        case .bumble: "drop.halffull"
        case .espressoTonic: "wineglass"
        default: isEspressoBased ? "cup.and.saucer" : "drop"
        }
    }
}

nonisolated public extension Brew {
    /// Bean name, or the method when no bean was recorded (café drinks, quick logs).
    var displayTitle: String {
        bean?.name ?? method.rawValue
    }

    /// The brewer or machine, under the method.
    var device: String? {
        (dripper ?? espressoMachine)?.name
    }
}
