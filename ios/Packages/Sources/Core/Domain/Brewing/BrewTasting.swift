import Foundation

/// How a brew tasted, from the rating screen: rating, flavor-wheel notes (Ukrainian names) and free notes.
public struct BrewTasting: Hashable, Codable, Sendable {
    /// 0...10 (the web app's default is 8).
    public var rating: Double
    public var flavors: [String]
    public var aromas: [String]
    public var notes: String

    public init(rating: Double = 8, flavors: [String] = [], aromas: [String] = [], notes: String = "") {
        self.rating = rating
        self.flavors = flavors
        self.aromas = aromas
        self.notes = notes
    }

    /// `brew` with this tasting (rating clamped, notes trimmed).
    func applied(to brew: Brew) -> Brew {
        var brew = brew
        brew.rating = Brew.clampRating(rating)
        brew.flavors = flavors
        brew.aromas = aromas
        brew.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return brew
    }
}
