import Foundation
import AppCore
import Domain
import BrewKit
import DesignSystem
import FlavorWheel

/// What the Journal shows (ROADMAP 3.6): a brew must match every part. The default shows everything.
nonisolated struct BrewFilter: Equatable, Sendable {
    static let ratingBounds: ClosedRange<Double> = 0...10

    /// The navigation bar's search text.
    var text = ""
    /// Any of these methods; empty for all.
    var methods: Set<BrewMethod> = []
    var rating = ratingBounds
    var isLikedOnly = false

    /// Set besides the search text (the chip row's Clear).
    var hasFilters: Bool { !methods.isEmpty || rating != Self.ratingBounds || isLikedOnly }
    var isEmpty: Bool { text.trimmed.isEmpty && !hasFilters }

    /// Drops the chips' filters, keeping the search text (the search bar clears that).
    mutating func clear() {
        self = BrewFilter(text: text)
    }

    /// "7.0–10.0" once the rating is narrowed.
    var ratingRangeText: String? {
        rating == Self.ratingBounds ? nil : "\(ratingText(rating.lowerBound))–\(ratingText(rating.upperBound))"
    }

    /// The filters that are on, for "Filtered by: …" (liked, rating, then methods by name).
    var summary: [String] {
        var parts = isLikedOnly ? [tr("Liked")] : []
        if let range = ratingRangeText { parts.append(tr("Rating \(range)")) }
        return parts + methods.map(\.rawValue).sorted()
    }

    func matches(_ brew: Brew) -> Bool {
        (methods.isEmpty || methods.contains(brew.method))
            && rating.contains(brew.rating)
            && (!isLikedOnly || brew.isLiked)
            && matchesText(brew)
    }

    /// The bag, roaster, café, method, brewer, notes and tags (also as the wheel shows them), ignoring
    /// case and diacritics.
    private func matchesText(_ brew: Brew) -> Bool {
        let query = text.trimmed
        guard !query.isEmpty else { return true }
        var texts = [brew.method.rawValue, brew.notes] + [brew.bean?.name, brew.bean?.roaster, brew.device].compactMap { $0 }
        if case .cafe(let place) = brew.origin { texts.append(place) }
        for tag in brew.flavors + brew.aromas {
            texts.append(tag)
            if let name = FlavorTaxonomy.path(forLabel: tag)?.localizedParts.last { texts.append(name) }
        }
        return texts.contains { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
}
