import SwiftUI
import AppCore

/// A capsule filled to `fraction` (0...1) in `color`, with optional marks: stock bars, the water poured.
public struct CapsuleProgress: View {
    private let fraction: Double
    private let color: Color
    private let height: CGFloat
    private let marks: [Double]

    public init(fraction: Double, color: Color, height: CGFloat = 6, marks: [Double] = []) {
        self.fraction = fraction.clamped(to: 0...1)
        self.color = color
        self.height = height
        self.marks = marks
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.theme.fill)
                Capsule().fill(color).frame(width: proxy.size.width * fraction)
                ForEach(marks, id: \.self) { mark in
                    Rectangle()
                        .fill(mark <= fraction ? Color.theme.textTertiary : color.opacity(0.6))
                        .frame(width: 2)
                        .offset(x: proxy.size.width * mark)
                }
            }
        }
        .frame(height: height)
        .animation(.smooth, value: fraction)
    }
}

/// `content` inside a ring that fills clockwise to `progress` (0...1): the rating, a timer button.
public struct ProgressRing<Content: View>: View {
    private let progress: Double
    private let color: Color
    private let track: Color
    private let lineWidth: CGFloat
    private let content: Content

    public init(progress: Double, color: Color, track: Color, lineWidth: CGFloat = 3, @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.color = color
        self.track = track
        self.lineWidth = lineWidth
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            content
        }
    }
}
