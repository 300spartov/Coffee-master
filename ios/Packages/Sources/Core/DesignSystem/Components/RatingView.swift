import SwiftUI

public struct RatingView: View {
    private let rating: Int
    private let maxRating: Int

    public init(rating: Int, maxRating: Int = 5) {
        self.rating = rating
        self.maxRating = maxRating
    }

    public var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
            }
        }
        .font(.caption)
        .foregroundStyle(Color.brandSecondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(rating) of \(maxRating) stars"))
    }
}

#Preview {
    RatingView(rating: 3)
}
