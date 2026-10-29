import SwiftUI

/// Circular 0–10 score, used on brew cards and the brew result screen.
public struct RatingRing: View {
    private let rating: Double
    private let size: CGFloat
    private let lineWidth: CGFloat

    public init(rating: Double, size: CGFloat = 48, lineWidth: CGFloat = 5) {
        self.rating = min(max(rating, 0), 10)
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle().stroke(.theme.fill, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: rating / 10)
                .stroke(.theme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(RatingFormat.value(rating))
                .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.theme.textPrimary)
        }
        .frame(width: size, height: size)
        .animation(.smooth, value: rating)
        .accessibilityElement()
        .accessibilityLabel(Text(RatingFormat.accessibilityLabel(rating)))
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
