import Domain

extension BrewMethod {
    var systemImage: String {
        switch category {
        case .filter: "drop"
        case .immersion: "cylinder"
        case .espresso: "cup.and.saucer.fill"
        }
    }

    /// Methods offered in the template's "New Brew" form.
    static let formPresets: [BrewMethod] = alternativePresets + espressoPresets
}

extension Brew {
    /// Bean name, or the method when no bean was recorded (café drinks, quick logs).
    var displayTitle: String {
        bean?.name ?? method.rawValue
    }
}
