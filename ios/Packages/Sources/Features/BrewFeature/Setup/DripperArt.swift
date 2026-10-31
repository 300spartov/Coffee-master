import SwiftUI
import Domain
import DesignSystem

/// The web app's dripper drawings (`bDripperArt`): origami, flower, AeroPress, and a cone for
/// everything else. Drawn in one theme color instead of the web's fixed palette, so it follows
/// light / dark mode. Coordinates are the web SVG's (`viewBox="0 6 124 90"`).
struct DripperArt: View {
    let kind: DripperKind
    var tint: Color = .theme.accent

    private static let viewBox = CGRect(x: 0, y: 6, width: 124, height: 90)

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / Self.viewBox.width, size.height / Self.viewBox.height)
            let offset = CGPoint(
                x: (size.width - Self.viewBox.width * scale) / 2 - Self.viewBox.minX * scale,
                y: (size.height - Self.viewBox.height * scale) / 2 - Self.viewBox.minY * scale
            )
            context.translateBy(x: offset.x, y: offset.y)
            context.scaleBy(x: scale, y: scale)
            draw(in: &context)
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        let line = GraphicsContext.Shading.color(tint)
        let faint = GraphicsContext.Shading.color(tint.opacity(0.45))
        let fill = GraphicsContext.Shading.color(tint.opacity(0.12))
        func stroke(_ path: Path, _ shading: GraphicsContext.Shading = line, width: CGFloat = 1.3) {
            context.stroke(path, with: shading, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }

        switch kind {
        case .origami:
            let body = Path.polygon([(26, 16), (33, 22), (40, 16), (47, 22), (54, 16), (62, 22), (70, 16), (77, 22), (84, 16), (91, 22), (98, 16), (62, 85)])
            context.fill(body, with: fill)
            stroke(body, width: 1.2)
            stroke(Path.lines(to: (62, 85), from: [(33, 22), (47, 22), (62, 22), (77, 22), (91, 22)]), faint, width: 1)
            stroke(Path.lines(to: (62, 85), from: [(40, 16), (84, 16)]), faint, width: 0.8)
            stroke(Path.ellipse(cx: 62, cy: 86, rx: 9, ry: 2.8), width: 1.2)

        case .flower:
            let cone = Path.polyline([(30, 17), (62, 80), (94, 17)])
            context.fill(cone, with: fill)
            stroke(cone)
            stroke(Path.ellipse(cx: 62, cy: 17, rx: 32, ry: 6.5))
            stroke(Path.ribs([
                ((44, 19), (49, 48), (60, 78)), ((54, 20), (57, 48), (61, 78)), ((62, 20), nil, (62, 78)),
                ((70, 20), (67, 48), (64, 78)), ((80, 19), (75, 48), (64, 78)), ((36, 18), (44, 46), (58, 78)),
                ((88, 18), (80, 46), (66, 78)),
            ]), faint, width: 1.5)
            stroke(Path.ellipse(cx: 62, cy: 86, rx: 22, ry: 4.6), width: 1.2)
            stroke(Path.lines([((52, 80), (52, 86)), ((72, 80), (72, 86))]), width: 1.2)
            stroke(Path.handle(from: (94, 23), control1: (108, 25), mid: (108, 39), control2: (108, 53), end: (92, 54)), width: 1.5)

        case .aeropress:
            let cap = Path(roundedRect: CGRect(x: 40, y: 9, width: 44, height: 7), cornerRadius: 3)
            context.fill(cap, with: fill)
            stroke(cap, width: 1.1)
            context.fill(Path(CGRect(x: 58, y: 14, width: 8, height: 6)), with: faint)
            var chamber = Path()
            chamber.move(to: CGPoint(x: 43, y: 20))
            chamber.addLine(to: CGPoint(x: 43, y: 80))
            chamber.addQuadCurve(to: CGPoint(x: 49, y: 86), control: CGPoint(x: 43, y: 86))
            chamber.addLine(to: CGPoint(x: 75, y: 86))
            chamber.addQuadCurve(to: CGPoint(x: 81, y: 80), control: CGPoint(x: 81, y: 86))
            chamber.addLine(to: CGPoint(x: 81, y: 20))
            chamber.closeSubpath()
            context.fill(chamber, with: fill)
            stroke(chamber)
            stroke(Path.lines([((45, 34), (79, 34)), ((45, 48), (79, 48)), ((45, 62), (79, 62))]), faint, width: 1)
            let base = Path.polygon([(41, 86), (83, 86), (79, 93), (45, 93)])
            context.fill(base, with: fill)
            stroke(base, width: 1.1)

        case .cone, .chemex, .frenchPress, .coldBrew, .batch:
            // The web app draws every other brewer as the cone.
            var cone = Path()
            cone.move(to: CGPoint(x: 28, y: 17))
            cone.addLine(to: CGPoint(x: 57, y: 82))
            cone.addQuadCurve(to: CGPoint(x: 67, y: 82), control: CGPoint(x: 62, y: 86))
            cone.addLine(to: CGPoint(x: 96, y: 17))
            context.fill(cone, with: fill)
            stroke(cone, width: 1.4)
            stroke(Path.ellipse(cx: 62, cy: 16, rx: 34, ry: 7), width: 1.4)
            stroke(Path.lines([((57, 82), (55, 88)), ((67, 82), (69, 88))]), width: 1.4)
            stroke(Path.ellipse(cx: 62, cy: 89, rx: 12, ry: 3.2), width: 1.4)
            stroke(Path.handle(from: (96, 24), control1: (112, 28), mid: (112, 42), control2: (112, 56), end: (96, 59)), width: 1.6)
            stroke(Path.ribs([
                ((40, 20), (50, 50), (58, 80)), ((50, 21), (57, 50), (61, 80)), ((62, 22), nil, (62, 80)),
                ((74, 21), (67, 50), (65, 80)), ((84, 20), (74, 50), (68, 80)), ((33, 19), (46, 48), (55, 80)),
                ((91, 19), (78, 48), (71, 80)),
            ]), faint, width: 1)
        }
    }
}

// MARK: - Path helpers (SVG-style coordinates)

private typealias XY = (CGFloat, CGFloat)

private extension CGPoint {
    init(_ xy: XY) { self.init(x: xy.0, y: xy.1) }
}

private extension Path {
    static func polyline(_ points: [XY]) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint($0) })
        return path
    }

    static func polygon(_ points: [XY]) -> Path {
        var path = polyline(points)
        path.closeSubpath()
        return path
    }

    static func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    static func lines(_ segments: [(XY, XY)]) -> Path {
        var path = Path()
        for (start, end) in segments {
            path.move(to: CGPoint(start))
            path.addLine(to: CGPoint(end))
        }
        return path
    }

    static func lines(to end: XY, from starts: [XY]) -> Path {
        lines(starts.map { ($0, end) })
    }

    /// Filter ribs: quadratic curves (`Q`), or straight lines when there's no control point.
    static func ribs(_ ribs: [(XY, XY?, XY)]) -> Path {
        var path = Path()
        for (start, control, end) in ribs {
            path.move(to: CGPoint(start))
            if let control {
                path.addQuadCurve(to: CGPoint(end), control: CGPoint(control))
            } else {
                path.addLine(to: CGPoint(end))
            }
        }
        return path
    }

    /// The side handle: two quadratic curves.
    static func handle(from start: XY, control1: XY, mid: XY, control2: XY, end: XY) -> Path {
        var path = Path()
        path.move(to: CGPoint(start))
        path.addQuadCurve(to: CGPoint(mid), control: CGPoint(control1))
        path.addQuadCurve(to: CGPoint(end), control: CGPoint(control2))
        return path
    }
}

#Preview {
    HStack(spacing: Spacing.lg) {
        ForEach([DripperKind.cone, .origami, .flower, .aeropress], id: \.self) { kind in
            DripperArt(kind: kind).frame(width: 80, height: 60)
        }
    }
    .padding()
}
