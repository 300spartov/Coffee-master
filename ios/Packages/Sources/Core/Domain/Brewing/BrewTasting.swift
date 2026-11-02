import Foundation
import AppCore

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
        brew.tasting = self
        brew.notes = brew.notes.trimmed
        return brew
    }
}

public extension Brew {
    /// The rating, flavors, aromas and notes (setting it clamps the rating).
    var tasting: BrewTasting {
        get { BrewTasting(rating: rating, flavors: flavors, aromas: aromas, notes: notes) }
        set {
            rating = Self.clampRating(newValue.rating)
            flavors = newValue.flavors
            aromas = newValue.aromas
            notes = newValue.notes
        }
    }

    /// The brew after editing it in the journal (web: `saveEditBrew`): the steps run back to back and
    /// give the total time; an espresso's time is its shot, and its ratio follows the yield.
    func edited() -> Brew {
        var brew = tasting.applied(to: self)
        if var shot = espresso {
            shot.doseGrams = doseGrams
            shot.actualYieldGrams = shot.actualYieldGrams.flatMap { $0 > 0 ? $0 : nil }
            brew.espresso = shot
            brew.totalTime = shot.shotTime
            if doseGrams > 0 { brew.ratio = shot.yieldGrams / doseGrams }
        } else {
            brew.steps = steps.resequenced()
            if let last = brew.steps.last { brew.totalTime = last.end }
        }
        return brew
    }
}
