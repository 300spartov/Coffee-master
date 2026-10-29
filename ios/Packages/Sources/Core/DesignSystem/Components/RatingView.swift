import SwiftUI

/// Compact 0–10 score, e.g. "★ 8.5".
public struct RatingView: View {
    private let rating: Double

    public init(rating: Double) {
        self.rating = rating
    }

    private var formattedRating: String {
        rating.formatted(.number.precision(.fractionLength(1)))
    }

    public var body: some View {
        Label {
            Text(rating, format: .number.precision(.fractionLength(1)))
                .monospacedDigit()
        } icon: {
            Image(systemName: "star.fill")
                .foregroundStyle(.theme.accent)
        }
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(tr("Rating \(formattedRating) of 10")))
    }
}

#Preview {
    RatingView(rating: 8.5)
}
