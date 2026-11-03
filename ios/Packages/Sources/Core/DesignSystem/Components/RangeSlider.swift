import SwiftUI
import AppCore

/// A slider with two thumbs for a range (e.g. a rating from–to), sized like the system slider: white
/// pills on iOS 26, white circles before. Each thumb is its own adjustable element for VoiceOver
/// (swipe up / down by `step`).
public struct RangeSlider: View {
    @Binding private var range: ClosedRange<Double>
    private let bounds: ClosedRange<Double>
    private let step: Double
    private let labels: (lower: String, upper: String)
    private let format: (Double) -> String

    private var isPill: Bool {
        if #available(iOS 26, *) { true } else { false }
    }
    private var thumbSize: CGSize { isPill ? CGSize(width: 38, height: 24) : CGSize(width: 28, height: 28) }
    private var trackHeight: CGFloat { isPill ? 6 : 4 }

    public init(
        _ range: Binding<ClosedRange<Double>>,
        in bounds: ClosedRange<Double>,
        step: Double,
        labels: (lower: String, upper: String),
        format: @escaping (Double) -> String
    ) {
        _range = range
        self.bounds = bounds
        self.step = step
        self.labels = labels
        self.format = format
    }

    public var body: some View {
        GeometryReader { geometry in
            let track = geometry.size.width - thumbSize.width
            let x = { (value: Double) in CGFloat((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * track }
            ZStack(alignment: .leading) {
                Capsule().fill(.theme.fill).frame(height: trackHeight).padding(.horizontal, thumbSize.width / 2)
                Capsule().fill(.theme.accent)
                    .frame(width: x(range.upperBound) - x(range.lowerBound), height: trackHeight)
                    .offset(x: x(range.lowerBound) + thumbSize.width / 2)
                // On top in the upper half, so thumbs that meet at the end can still be pulled apart.
                thumb(isLower: true, track: track).offset(x: x(range.lowerBound))
                    .zIndex(range.lowerBound > (bounds.lowerBound + bounds.upperBound) / 2 ? 1 : 0)
                thumb(isLower: false, track: track).offset(x: x(range.upperBound))
            }
            .frame(maxHeight: .infinity)
            .coordinateSpace(.named(Self.space))
        }
        .frame(height: thumbSize.height + Spacing.lg)
    }

    private func thumb(isLower: Bool, track: CGFloat) -> some View {
        let value = isLower ? range.lowerBound : range.upperBound
        return Capsule()
            .fill(.white)
            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .contentShape(Capsule())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named(RangeSlider.space)).onChanged { drag in
                let fraction = Double((drag.location.x - thumbSize.width / 2) / max(track, 1))
                set(bounds.lowerBound + fraction * (bounds.upperBound - bounds.lowerBound), isLower: isLower)
            })
            .accessibilityElement()
            .accessibilityLabel(isLower ? labels.lower : labels.upper)
            .accessibilityValue(format(value))
            .accessibilityAdjustableAction { direction in
                set(value + (direction == .increment ? step : -step), isLower: isLower)
            }
    }

    /// Snaps to `step` and keeps the thumbs in order (they may meet). Writes only a new value, so a
    /// drag within one step doesn't redraw whatever depends on the range.
    private func set(_ value: Double, isLower: Bool) {
        let snapped = ((value / step).rounded() * step).clamped(to: bounds)
        let new = isLower ? min(snapped, range.upperBound)...range.upperBound : range.lowerBound...max(snapped, range.lowerBound)
        if new != range { range = new }
    }

    private static let space = "RangeSlider"
}

#Preview {
    @Previewable @State var range = 6.0...10.0
    RangeSlider($range, in: 0...10, step: 0.5, labels: ("From", "To")) { $0.formatted() }
        .padding()
}
