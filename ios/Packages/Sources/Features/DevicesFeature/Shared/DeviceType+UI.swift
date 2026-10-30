import Domain

extension DeviceType {
    /// Categories shown in the grid, in order. Filter packs are stock (ROADMAP 1.4), not catalog devices.
    static let browsable: [DeviceType] = [.dripper, .espressoMachine, .grinder, .kettle, .accessory]

    var title: String {
        switch self {
        case .dripper: tr("Brewers")
        case .espressoMachine: tr("Espresso machines")
        case .grinder: tr("Grinders")
        case .kettle: tr("Kettles")
        case .filter: tr("Filters")
        case .accessory: tr("Accessories")
        }
    }

    var systemImage: String {
        switch self {
        case .dripper: "drop"
        case .espressoMachine: "cup.and.saucer.fill"
        case .grinder: "gearshape.2"
        case .kettle: "waterbottle"
        case .filter: "line.3.horizontal.decrease"
        case .accessory: "wrench.and.screwdriver"
        }
    }
}
