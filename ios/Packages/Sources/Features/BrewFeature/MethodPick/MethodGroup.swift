import Domain
import BrewKit

/// The two ways to brew, as on the web's first wizard screen.
nonisolated public enum MethodGroup: String, CaseIterable, Sendable {
    case alternative
    case espresso

    /// The methods offered in this group, in the web app's order.
    public var methods: [BrewMethod] {
        switch self {
        case .alternative: BrewMethod.alternativePresets
        case .espresso: BrewMethod.espressoPresets
        }
    }

    var title: String {
        switch self {
        case .alternative: tr("Alternative")
        case .espresso: tr("Espresso")
        }
    }

    /// Under the title on the group card.
    var summary: String {
        switch self {
        case .alternative: tr("V60 · Aeropress · Chemex · French Press & more")
        case .espresso: tr("Shot · Timer · Ratio · TDS")
        }
    }

    /// Under the title on the methods screen.
    var prompt: String {
        switch self {
        case .alternative: tr("Choose a method")
        case .espresso: tr("Choose a drink")
        }
    }

    var systemImage: String {
        switch self {
        case .alternative: "line.3.horizontal.decrease"
        case .espresso: "cup.and.saucer.fill"
        }
    }
}
