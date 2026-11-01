import Foundation

/// Where the wheel is: categories, a category's groups, or a group's notes.
nonisolated public struct WheelPosition: Equatable, Sendable {
    public var categoryID: String?
    public var groupID: String?

    public init(category: String? = nil, group: String? = nil) {
        categoryID = category
        groupID = group
    }
}

/// What tapping a part of the wheel does.
nonisolated public enum WheelAction: Equatable, Sendable {
    /// A block of the current ring: opens a category or group, or toggles a note.
    case pick(FlavorPath)
    /// Back to a level (a passed ring, or the center).
    case go(WheelPosition)
}

/// The wheel's geometry for a position, in a 360 × 360 box centered on 0,0 (the web SVG's units),
/// angles in radians from 12 o'clock, clockwise. Drawing and hit-testing both use it.
nonisolated struct WheelLayout {
    /// A block in the outer ring: the current level's options.
    struct Segment: Equatable {
        let path: FlavorPath
        let label: String
        let color: UInt32
        let innerRadius: Double
        let outerRadius: Double
        let startAngle: Double
        let endAngle: Double
        /// Dimmed by the search (and then not tappable).
        let isDimmed: Bool
        /// A picked note: drawn raised.
        let isLifted: Bool
        /// Picks inside a category or group, or nil.
        let badge: Int?

        /// Categories and groups open a deeper ring ("›").
        var opensDeeper: Bool { path.level < 3 }
        var midAngle: Double { (startAngle + endAngle) / 2 }
        var midRadius: Double { (innerRadius + outerRadius) / 2 }
    }

    /// A full ring for a level passed through (faded); tapping it goes back there.
    struct Crumb: Equatable {
        let innerRadius: Double
        let outerRadius: Double
        let label: String
        let color: UInt32
        let target: WheelPosition
    }

    static let size = 360.0
    static let outerRadius = 172.0

    let segments: [Segment]
    let crumbs: [Crumb]
    let hubRadius: Double
    /// Where the center goes back to (nil on the first level).
    let hubTarget: WheelPosition?
    /// The open category's color, for the hub's ring.
    let hubColor: UInt32?

    init(position: WheelPosition, selection: FlavorSelection, search: FlavorSearch?) {
        func ring(_ inner: Double, _ entries: [(path: FlavorPath, name: FlavorName, color: UInt32)]) -> [Segment] {
            let step = 2 * Double.pi / Double(max(entries.count, 1))
            return entries.enumerated().map { index, entry in
                let inside = entry.path.level < 3 ? selection.count(under: entry.path) : 0
                return Segment(
                    path: entry.path,
                    label: entry.name.localized,
                    color: entry.color,
                    innerRadius: inner,
                    outerRadius: Self.outerRadius,
                    startAngle: Double(index) * step,
                    endAngle: Double(index + 1) * step,
                    isDimmed: search.map { !$0.matches(entry.path) } ?? false,
                    isLifted: entry.path.level == 3 && selection.isPicked(entry.path),
                    badge: inside > 0 ? inside : nil
                )
            }
        }

        let category = position.categoryID.flatMap(FlavorTaxonomy.category)
        let groupIndex = category?.groups.firstIndex { $0.id == position.groupID }

        if let category, let groupIndex {
            // Level 3: the group's notes.
            let group = category.groups[groupIndex]
            segments = ring(126, group.notes.enumerated().map { index, note in
                (FlavorPath(category: category.id, group: group.id, note: note.uk), note, FlavorColor.note(category, groupIndex, index, of: group.notes.count))
            })
            // A single-group category has no groups ring: back goes to the categories.
            let groupsLevel = category.groups.count == 1 ? WheelPosition() : WheelPosition(category: category.id)
            crumbs = [
                Crumb(innerRadius: 44, outerRadius: 78, label: category.name.localized, color: category.color, target: WheelPosition()),
                Crumb(innerRadius: 84, outerRadius: 120, label: group.name.localized, color: FlavorColor.group(category, groupIndex), target: groupsLevel),
            ]
            hubTarget = groupsLevel
        } else if let category {
            // Level 2: the category's groups.
            segments = ring(96, category.groups.enumerated().map { index, group in
                (FlavorPath(category: category.id, group: group.id), group.name, FlavorColor.group(category, index))
            })
            crumbs = [Crumb(innerRadius: 44, outerRadius: 90, label: category.name.localized, color: category.color, target: WheelPosition())]
            hubTarget = WheelPosition()
        } else {
            // Level 1: categories.
            segments = ring(100, FlavorTaxonomy.categories.map { (FlavorPath(category: $0.id), $0.name, $0.color) })
            crumbs = []
            hubTarget = nil
        }
        hubRadius = category == nil ? 96 : 40
        hubColor = category?.color
    }

    /// What a tap at `point` (in layout units, relative to the center) does.
    func action(at point: CGPoint) -> WheelAction? {
        let radius = hypot(point.x, point.y)
        if radius <= hubRadius { return hubTarget.map(WheelAction.go) }
        // Clockwise from 12 o'clock, 0..<2π.
        var angle = atan2(Double(point.x), Double(-point.y))
        if angle < 0 { angle += 2 * .pi }
        if let segment = segments.first(where: {
            radius >= $0.innerRadius - ($0.isLifted ? 3 : 0) && radius <= $0.outerRadius + ($0.isLifted ? 5 : 0)
                && angle >= $0.startAngle && angle < $0.endAngle
        }) {
            return segment.isDimmed ? nil : .pick(segment.path)
        }
        return crumbs.first { radius >= $0.innerRadius && radius <= $0.outerRadius }.map { .go($0.target) }
    }
}

/// The web wheel's color ramps: groups shade from darker to lighter within their category's color,
/// notes within their group's.
nonisolated enum FlavorColor {
    static func group(_ category: FlavorCategory, _ index: Int) -> UInt32 {
        let count = category.groups.count
        guard count > 1 else { return category.color }
        return shade(category.color, -0.18 + Double(index) / Double(count - 1) * 0.5)
    }

    static func note(_ category: FlavorCategory, _ groupIndex: Int, _ index: Int, of count: Int) -> UInt32 {
        shade(group(category, groupIndex), -0.12 + Double(index) / Double(max(1, count - 1)) * 0.4)
    }

    /// Lighter towards white (`amount` > 0) or darker towards black (< 0).
    static func shade(_ color: UInt32, _ amount: Double) -> UInt32 {
        [16, 8, 0].reduce(UInt32(0)) { result, shift in
            let value = Double((color >> UInt32(shift)) & 0xff)
            let shaded = amount >= 0 ? value + (255 - value) * amount : value * (1 + amount)
            return (result << 8) | UInt32(min(max(shaded.rounded(), 0), 255))
        }
    }

    /// Whether text on `color` should be dark (light backgrounds) rather than white.
    static func wantsDarkText(_ color: UInt32) -> Bool {
        let r = Double((color >> 16) & 0xff), g = Double((color >> 8) & 0xff), b = Double(color & 0xff)
        return 0.299 * r + 0.587 * g + 0.114 * b > 150
    }
}
