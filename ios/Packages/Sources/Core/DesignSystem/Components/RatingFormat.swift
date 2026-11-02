import Foundation

/// "Rating 8.5 of 10", for VoiceOver (`RatingRing`).
nonisolated func ratingAccessibilityLabel(_ rating: Double) -> String {
    let value = ratingText(rating)
    return tr("Rating \(value) of 10")
}
