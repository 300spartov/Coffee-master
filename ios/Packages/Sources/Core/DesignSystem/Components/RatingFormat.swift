import Foundation

/// Shared text for 0–10 ratings (`RatingView`, `RatingRing`).
enum RatingFormat {
    /// "8.5" (one decimal, localized separator).
    static func value(_ rating: Double) -> String {
        rating.formatted(.number.precision(.fractionLength(1)))
    }

    /// "Rating 8.5 of 10", for VoiceOver.
    static func accessibilityLabel(_ rating: Double) -> String {
        tr("Rating \(value(rating)) of 10")
    }
}
