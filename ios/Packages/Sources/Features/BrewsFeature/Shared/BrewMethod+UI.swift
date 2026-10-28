import Domain

extension BrewMethod {
    var systemImage: String {
        switch self {
        case .v60: "drop"
        case .aeropress: "cylinder"
        case .espresso: "cup.and.saucer.fill"
        case .frenchPress: "mug"
        case .chemex: "hourglass"
        }
    }
}
