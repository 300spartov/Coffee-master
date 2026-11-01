import Foundation

/// What's picked on one wheel (flavor or aroma), with the web app's rules: you can pick at any level,
/// and the deepest pick in a branch replaces the shallower one.
nonisolated public struct FlavorSelection: Equatable, Sendable {
    public private(set) var paths: Set<FlavorPath> = []

    public init(labels: [String] = []) {
        paths = Set(labels.compactMap(FlavorTaxonomy.path(forLabel:)))
    }

    /// Saved with the brew: the picks in wheel order (category, then level), as Ukrainian names.
    public var labels: [String] { sorted.map(\.storedLabel) }

    /// The picks in wheel order.
    public var sorted: [FlavorPath] {
        let order = Dictionary(uniqueKeysWithValues: FlavorTaxonomy.categories.enumerated().map { ($1.id, $0) })
        return paths.sorted {
            (order[$0.categoryID] ?? 0, $0.level, $0.storedLabel) < (order[$1.categoryID] ?? 0, $1.level, $1.storedLabel)
        }
    }

    public var count: Int { paths.count }

    public func isPicked(_ path: FlavorPath) -> Bool { paths.contains(path) }

    /// Picks inside a category or group (for the badges).
    public func count(under path: FlavorPath) -> Int {
        paths.filter { $0.categoryID == path.categoryID && (path.groupID == nil || $0.groupID == path.groupID) }.count
    }

    /// A tap on the wheel:
    /// - a category is picked when opened, if nothing in it is picked yet;
    /// - a group replaces the bare category, if nothing in it is picked yet;
    /// - a note toggles; picking it replaces its group, unpicking the last one brings the group back.
    public mutating func pick(_ path: FlavorPath) {
        let group = FlavorPath(category: path.categoryID, group: path.groupID)
        switch path.level {
        case 1:
            if count(under: path) == 0 { paths.insert(path) }
        case 2:
            paths.remove(FlavorPath(category: path.categoryID))
            if count(under: path) == 0 { paths.insert(path) }
        default:
            if paths.remove(path) == nil {
                paths.insert(path)
                paths.remove(group)
            } else if count(under: group) == 0 {
                paths.insert(group)
            }
        }
    }

    public mutating func remove(_ path: FlavorPath) {
        paths.remove(path)
    }

    public mutating func reset() {
        paths = []
    }
}

/// The parts of the wheel matching a search (notes, groups and categories, in either language).
nonisolated public struct FlavorSearch: Sendable {
    private let paths: Set<FlavorPath>

    /// `nil` for an empty query (nothing is dimmed).
    public init?(_ query: String) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        var paths = Set<FlavorPath>()
        for category in FlavorTaxonomy.categories {
            let categoryPath = FlavorPath(category: category.id)
            if category.name.matches(query) { paths.insert(categoryPath) }
            for group in category.groups {
                let groupPath = FlavorPath(category: category.id, group: group.id)
                let notes = group.notes.filter { $0.matches(query) }.map { FlavorPath(category: category.id, group: group.id, note: $0.uk) }
                paths.formUnion(notes)
                if group.name.matches(query) || !notes.isEmpty { paths.formUnion([groupPath, categoryPath]) }
            }
        }
        self.paths = paths
    }

    public func matches(_ path: FlavorPath) -> Bool { paths.contains(path) }
}
