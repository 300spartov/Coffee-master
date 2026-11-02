import AppCore
import SwiftUI

/// Circular 0–10 score in its rating color, used on brew cards and the rating screens.
public struct RatingRing: View {
    private let rating: Double
    private let size: CGFloat
    private let lineWidth: CGFloat

    public init(rating: Double, size: CGFloat = 48, lineWidth: CGFloat = 5) {
        self.rating = rating.clamped(to: 0...10)
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ProgressRing(progress: rating / 10, color: .rating(rating), track: .theme.fill, lineWidth: lineWidth) {
            Text(ratingText(rating))
                .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.theme.textPrimary)
        }
        .frame(width: size, height: size)
        .animation(.smooth, value: rating)
        .accessibilityElement()
        .accessibilityLabel(Text(ratingAccessibilityLabel(rating)))
    }
}

public extension Color {
    /// The web's rating colors: green from 8, amber from 5, red below.
    static func rating(_ rating: Double) -> Color {
        rating >= 8 ? .theme.success : (rating >= 5 ? .theme.warning : .theme.error)
    }
}

#Preview {
    HStack(spacing: Spacing.lg) {
        RatingRing(rating: 9.2)
        RatingRing(rating: 6.5, size: 64, lineWidth: 6)
        RatingRing(rating: 3)
    }
    .padding()
}
