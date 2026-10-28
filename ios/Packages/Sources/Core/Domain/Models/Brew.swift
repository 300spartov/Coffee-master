import Foundation

public struct Brew: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var method: BrewMethod
    public var beanName: String
    public var doseGrams: Double
    public var waterGrams: Double
    public var brewTime: TimeInterval
    /// 1...5
    public var rating: Int
    public var date: Date

    public init(
        id: String = UUID().uuidString,
        method: BrewMethod,
        beanName: String,
        doseGrams: Double,
        waterGrams: Double,
        brewTime: TimeInterval,
        rating: Int,
        date: Date = .now
    ) {
        self.id = id
        self.method = method
        self.beanName = beanName
        self.doseGrams = doseGrams
        self.waterGrams = waterGrams
        self.brewTime = brewTime
        self.rating = rating
        self.date = date
    }

    /// Water-to-coffee ratio, e.g. `16` for 1:16.
    public var ratio: Double {
        doseGrams > 0 ? waterGrams / doseGrams : 0
    }
}

public enum BrewMethod: String, CaseIterable, Codable, Sendable {
    case v60
    case aeropress
    case espresso
    case frenchPress
    case chemex

    public var title: String {
        switch self {
        case .v60: "V60"
        case .aeropress: "AeroPress"
        case .espresso: "Espresso"
        case .frenchPress: "French Press"
        case .chemex: "Chemex"
        }
    }
}
