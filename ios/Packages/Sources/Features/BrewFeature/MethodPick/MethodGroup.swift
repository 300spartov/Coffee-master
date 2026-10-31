import Domain

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

nonisolated extension BrewMethod {
    /// Icon on the method tile (the web's per-method icons, in SF Symbols).
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
