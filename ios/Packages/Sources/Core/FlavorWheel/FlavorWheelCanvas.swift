import SwiftUI
import DesignSystem

/// Draws a `WheelLayout` and turns taps into `WheelAction`s. Each block also gets an invisible
/// accessibility element at its middle, so VoiceOver (and UI tests) can find it; taps on it fall
/// through to the wheel's own hit-testing.
struct FlavorWheelCanvas: View {
    let layout: WheelLayout
    let hubTitle: String
    let hubSubtitle: String
    let perform: (WheelAction) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let scale = side / WheelLayout.size
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            ZStack {
                Canvas { context, _ in
                    context.translateBy(x: center.x, y: center.y)
                    context.scaleBy(x: scale, y: scale)
                    draw(in: &context)
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { tap in
                    let point = CGPoint(x: (tap.location.x - center.x) / scale, y: (tap.location.y - center.y) / scale)
                    if let action = layout.action(at: point) { perform(action) }
                })
                accessibilityTargets(center: center, scale: scale)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext) {
        for crumb in layout.crumbs {
            var ring = Path()
            ring.addEllipse(in: circle(crumb.outerRadius))
            ring.addEllipse(in: circle(crumb.innerRadius))
            context.fill(ring, with: .color(Color(hex: crumb.color).opacity(0.32)), style: FillStyle(eoFill: true))
            let mid = (crumb.innerRadius + crumb.outerRadius) / 2
            drawText(crumb.label, at: CGPoint(x: 0, y: -mid - 3), size: 9.5, color: .theme.textPrimary, in: &context)
            drawText("‹ " + tr("back"), at: CGPoint(x: 0, y: -mid + 8), size: 6.5, color: .theme.textSecondary, in: &context, bold: false)
        }

        for segment in layout.segments where !segment.isLifted {
            drawSegment(segment, in: &context)
        }
        // Picked notes on top, with a shadow.
        var lifted = context
        lifted.addFilter(.shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 2))
        for segment in layout.segments where segment.isLifted {
            drawSegment(segment, in: &lifted)
        }

        // Hub
        var hub = context
        hub.addFilter(.shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 3))
        hub.fill(Path(ellipseIn: circle(layout.hubRadius - 3)), with: .color(.theme.elevatedSurface))
        hub.stroke(
            Path(ellipseIn: circle(layout.hubRadius - 3)),
            with: .color(layout.hubColor.map { Color(hex: $0) } ?? .theme.separator),
            lineWidth: layout.hubColor == nil ? 1.4 : 2
        )
        if layout.hubTarget == nil {
            drawText(hubTitle, at: CGPoint(x: 0, y: -14), size: 30, color: .theme.accent, in: &context)
            drawText(hubSubtitle, at: CGPoint(x: 0, y: 18), size: 11, color: .theme.textSecondary, in: &context, bold: false)
        } else {
            drawText("‹", at: CGPoint(x: 0, y: -7), size: 22, color: layout.hubColor.map { Color(hex: $0) } ?? .theme.accent, in: &context)
            drawText(tr("back"), at: CGPoint(x: 0, y: 12), size: 7.5, color: .theme.textSecondary, in: &context, bold: false)
        }
    }

    private func drawSegment(_ segment: WheelLayout.Segment, in context: inout GraphicsContext) {
        let inner = segment.innerRadius - (segment.isLifted ? 3 : 0)
        let outer = segment.outerRadius + (segment.isLifted ? 5 : 0)
        let color = Color(hex: segment.color)
        let path = sector(inner, outer, segment.startAngle, segment.endAngle, gap: 0.014)
        let opacity = segment.isDimmed ? 0.16 : (segment.opensDeeper || segment.isLifted ? 1 : 0.82)
        context.fill(path, with: .color(color.opacity(opacity)))
        context.stroke(
            path,
            with: .color(segment.isLifted ? Color.white.opacity(0.9) : Color(hex: FlavorColor.shade(segment.color, -0.3)).opacity(opacity)),
            style: StrokeStyle(lineWidth: segment.isLifted ? 1.6 : 1, lineJoin: .round)
        )
        guard !segment.isDimmed else { return }

        let textColor: Color = FlavorColor.wantsDarkText(segment.color) ? Color(hex: 0x1a1206) : .white
        let arc = (segment.endAngle - segment.startAngle) * segment.midRadius
        let size = max(8.5, min(13, arc / (Double(segment.label.count) * 0.6)))
        drawText(segment.label, at: point(segment.midRadius, segment.midAngle), size: size, color: textColor, rotation: tangent(segment.midAngle), in: &context)
        if segment.opensDeeper {
            drawText("›", at: point(outer - 12, segment.midAngle), size: 12, color: textColor.opacity(0.7), rotation: tangent(segment.midAngle), in: &context)
        }
        if let badge = segment.badge {
            drawBadge(String(badge), at: point(inner + 11, segment.midAngle), in: &context)
        }
        if segment.isLifted {
            drawBadge("✓", at: point(outer - 11, segment.midAngle), in: &context)
        }
    }

    private func drawBadge(_ text: String, at center: CGPoint, in context: inout GraphicsContext) {
        let rect = CGRect(x: center.x - 8.5, y: center.y - 8.5, width: 17, height: 17)
        context.fill(Path(ellipseIn: rect), with: .color(.theme.accent))
        drawText(text, at: center, size: 8, color: Color(hex: 0x1c130a), in: &context)
    }

    private func drawText(
        _ text: String,
        at point: CGPoint,
        size: Double,
        color: Color,
        rotation: Double = 0,
        in context: inout GraphicsContext,
        bold: Bool = true
    ) {
        var context = context
        context.translateBy(x: point.x, y: point.y)
        context.rotate(by: .radians(rotation))
        context.draw(Text(verbatim: text).font(.system(size: size, weight: bold ? .bold : .medium)).foregroundColor(color), at: .zero)
    }

    // MARK: - Geometry

    /// Angle from 12 o'clock (clockwise) → point.
    private func point(_ radius: Double, _ angle: Double) -> CGPoint {
        CGPoint(x: sin(angle) * radius, y: -cos(angle) * radius)
    }

    /// Text along the ring, kept upright on the lower half.
    private func tangent(_ angle: Double) -> Double {
        angle > .pi / 2 && angle < .pi * 1.5 ? angle + .pi : angle
    }

    private func circle(_ radius: Double) -> CGRect {
        CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
    }

    private func sector(_ inner: Double, _ outer: Double, _ start: Double, _ end: Double, gap: Double) -> Path {
        var (a1, a2) = (start + gap, end - gap)
        if a2 <= a1 { (a1, a2) = (start, end) }
        // SwiftUI angles: from 3 o'clock; ours from 12 o'clock.
        let s = Angle.radians(a1 - .pi / 2), e = Angle.radians(a2 - .pi / 2)
        var path = Path()
        path.addArc(center: .zero, radius: outer, startAngle: s, endAngle: e, clockwise: false)
        path.addArc(center: .zero, radius: inner, startAngle: e, endAngle: s, clockwise: true)
        path.closeSubpath()
        return path
    }

    // MARK: - Accessibility

    private func accessibilityTargets(center: CGPoint, scale: Double) -> some View {
        ZStack {
            ForEach(Array(layout.segments.enumerated()), id: \.offset) { _, segment in
                let mid = point(segment.midRadius, segment.midAngle)
                Color.clear
                    .frame(width: 24, height: 24)
                    .position(x: center.x + mid.x * scale, y: center.y + mid.y * scale)
                    .accessibilityElement()
                    .accessibilityLabel(segment.label)
                    .accessibilityAddTraits(segment.isLifted ? [.isButton, .isSelected] : .isButton)
                    .accessibilityAction { if !segment.isDimmed { perform(.pick(segment.path)) } }
                    .accessibilityIdentifier("wheel.\(segment.label)")
            }
            if let back = layout.hubTarget {
                Color.clear
                    .frame(width: 24, height: 24)
                    .position(center)
                    .accessibilityElement()
                    .accessibilityLabel(tr("back"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { perform(.go(back)) }
                    .accessibilityIdentifier("wheel.back")
            }
        }
        .allowsHitTesting(false)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}
