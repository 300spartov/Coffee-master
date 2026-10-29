import SwiftUI

/// How full a bag of beans or a pack of filters is.
public enum StockLevel: Equatable, Sendable {
    case empty
    case low
    case normal

    /// `low` at or below `lowThreshold` of the total (default 20 %).
    public init(fraction: Double, lowThreshold: Double = 0.2) {
        if fraction <= 0 {
            self = .empty
        } else if fraction <= lowThreshold {
            self = .low
        } else {
            self = .normal
        }
    }

    var color: Color {
        switch self {
        case .empty: .theme.error
        case .low: .theme.warning
        case .normal: .theme.accent
        }
    }
}

/// Thin progress bar for remaining stock: "160 / 250 g".
public struct StockBar: View {
    private let fraction: Double
    private let level: StockLevel

    public init(fraction: Double, level: StockLevel? = nil) {
        self.fraction = min(max(fraction, 0), 1)
        self.level = level ?? StockLevel(fraction: fraction)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.theme.fill)
                Capsule()
                    .fill(level.color)
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 6)
        .animation(.smooth, value: fraction)
        .accessibilityElement()
        .accessibilityLabel(Text(tr("Remaining")))
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        StockBar(fraction: 0.64)
        StockBar(fraction: 0.12)
        StockBar(fraction: 0)
    }
    .padding()
}
