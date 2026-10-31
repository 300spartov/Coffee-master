import Foundation

/// Which brewer a pack of filters is made for.
public enum FilterShape: String, Codable, Sendable, CaseIterable {
    /// V60 and other cone drippers.
    case cone
    /// Kalita Wave and other flat-bottom drippers.
    case flatBottom
    case chemex
    case aeropress
    /// Basket filters for batch brewers / drip machines.
    case basket

    /// Proper names, the same in every language.
    public var displayName: String {
        switch self {
        case .cone: "V60"
        case .flatBottom: "Kalita Wave"
        case .chemex: "Chemex"
        case .aeropress: "AeroPress"
        case .basket: "Batch Brewing"
        }
    }

    /// The shapes `method`'s brewer takes, the usual one first. Empty: any filter will do (French
    /// press, cold brew).
    public static func shapes(for method: BrewMethod) -> [FilterShape] {
        switch method {
        case .chemex: [.chemex]
        case .aeropress: [.aeropress]
        case .batchBrewing: [.basket, .cone]
        case .frenchPress, .coldBrew: []
        default: [.cone, .flatBottom]
        }
    }
}

public extension FilterPack {
    /// Packs without a shape (older and imported ones) fit any brew.
    func fits(_ method: BrewMethod) -> Bool {
        guard let shape else { return true }
        let shapes = FilterShape.shapes(for: method)
        return shapes.isEmpty || shapes.contains(shape)
    }
}
