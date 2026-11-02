import AppCore
import SwiftUI

/// How full a bag of beans or a pack of filters is.
nonisolated public enum StockLevel: Equatable, Sendable {
    case empty
    case low
    case normal

    /// From the item's own rules (`Bean.isLow`, `FilterPack.isLow`, …).
    public init(isEmpty: Bool, isLow: Bool) {
        self = isEmpty ? .empty : (isLow ? .low : .normal)
    }

    public init(_ item: some Stocked) {
        self.init(isEmpty: item.isEmpty, isLow: item.isLow)
    }

    /// Accent when there's plenty, warning when low, error when empty.
    public var color: Color {
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

    public init(fraction: Double, level: StockLevel) {
        self.fraction = fraction.clamped(to: 0...1)
        self.level = level
    }

    /// A bag or pack: how full, in its stock level's color.
    public init(_ item: some Stocked) {
        self.init(fraction: item.remainingFraction, level: StockLevel(item))
    }

    public var body: some View {
        CapsuleProgress(fraction: fraction, color: level.color)
            .accessibilityElement()
        .accessibilityLabel(Text(tr("Remaining")))
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

/// "Running low" / "Empty" capsule for a stock level; nothing when there's plenty.
public struct StockBadge: View {
    private let level: StockLevel

    public init(level: StockLevel) {
        self.level = level
    }

    public var body: some View {
        switch level {
        case .empty: badge(tr("Empty"))
        case .low: badge(tr("Running low"), systemImage: "exclamationmark.triangle.fill")
        case .normal: EmptyView()
        }
    }

    private func badge(_ title: String, systemImage: String? = nil) -> some View {
        HStack(spacing: Spacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title).fontWeight(.semibold)
        }
        .font(.caption2)
        .foregroundStyle(level.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(level.color.opacity(0.12), in: Capsule())
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        StockBadge(level: .low)
        StockBadge(level: .empty)
        StockBar(fraction: 0.64, level: .normal)
        StockBar(fraction: 0.12, level: .low)
        StockBar(fraction: 0, level: .empty)
    }
    .padding()
}
