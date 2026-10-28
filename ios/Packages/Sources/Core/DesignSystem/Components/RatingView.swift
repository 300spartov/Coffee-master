import SwiftUI

/// Compact 0–10 score, e.g. "★ 8.5".
public struct RatingView: View {
    private let rating: Double

    public init(rating: Double) {
        self.rating = rating
    }

    public var body: some View {
        Label {
            Text(rating, format: .number.precision(.fractionLength(1)))
                .monospacedDigit()
        } icon: {
            // Explicit accent: list rows often override `.tint` for their text.
            Image(systemName: "star.fill")
                .foregroundStyle(Color.accentColor)
        }
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Rating \(rating, format: .number.precision(.fractionLength(1))) of 10"))
    }
}

#Preview {
    RatingView(rating: 8.5)
}
