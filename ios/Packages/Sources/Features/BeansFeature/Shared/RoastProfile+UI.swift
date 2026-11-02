import Domain

extension RoastProfile {
    var title: String {
        switch self {
        case .filter: tr("Filter")
        case .espresso: tr("Espresso")
        case .omni: tr("Omni")
        }
    }
}
