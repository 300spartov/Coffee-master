import Domain

/// What a setup row picks.
nonisolated public enum GearKind: String, Sendable, CaseIterable {
    case bean
    case dripper
    case filter
    case grinder
    case espressoMachine

    /// Placeholder on the setup row and the picker's title. The dripper wording follows the method
    /// ("Choose Aeropress"), like the web app.
    func prompt(for method: BrewMethod) -> String {
        switch self {
        case .bean: tr("Choose a bag")
        case .filter: tr("Choose a filter")
        case .grinder: tr("Choose a grinder")
        case .espressoMachine: tr("Choose an espresso machine")
        case .dripper:
            switch DripperKind.required(for: method) {
            case .aeropress: tr("Choose Aeropress")
            case .chemex: tr("Choose Chemex")
            case .frenchPress: tr("Choose French Press")
            case .coldBrew: tr("Choose a cold brew device")
            case .batch: tr("Choose a device")
            default: tr("Choose a dripper")
            }
        }
    }

    /// Owned devices of this kind live under this device type.
    var deviceType: DeviceType? {
        switch self {
        case .dripper: .dripper
        case .grinder: .grinder
        case .espressoMachine: .espressoMachine
        case .bean, .filter: nil
        }
    }
}

extension GearKind {
    var systemImage: String {
        switch self {
        case .bean: "leaf.fill"
        case .dripper: "drop"
        case .filter: "line.3.horizontal.decrease"
        case .grinder: "gearshape.2"
        case .espressoMachine: "cup.and.saucer.fill"
        }
    }

    var emptyTitle: String {
        switch self {
        case .bean: tr("No beans yet")
        case .filter: tr("No filter packs")
        case .dripper, .grinder, .espressoMachine: tr("No devices yet")
        }
    }

    var emptyMessage: String {
        switch self {
        case .bean: tr("Add the coffee you have at home.")
        case .filter: tr("Add the paper filters you have.")
        case .dripper, .grinder, .espressoMachine: tr("Add the one you use.")
        }
    }
}

/// A picked item, handed from the picker back to the setup.
public enum GearPick: Equatable, Sendable {
    case bean(Bean)
    case device(Device)
    case filterPack(FilterPack)
}
