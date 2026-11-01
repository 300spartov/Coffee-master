import Foundation
import AppCore

/// A name in both languages. Brews store the Ukrainian one (the web app's key).
nonisolated public struct FlavorName: Hashable, Sendable {
    public let uk: String
    public let en: String

    public init(_ uk: String, _ en: String) {
        self.uk = uk
        self.en = en
    }

    /// In the in-app language.
    public var localized: String {
        LanguageSettings.shared.current == .english ? en : uk
    }

    func matches(_ query: String) -> Bool {
        uk.localizedCaseInsensitiveContains(query) || en.localizedCaseInsensitiveContains(query)
    }
}

nonisolated public struct FlavorCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: FlavorName
    /// The wheel's color for the category (the flavor wheel's own palette, like a chart's; not a theme role).
    public let color: UInt32
    public let groups: [FlavorGroup]
}

nonisolated public struct FlavorGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: FlavorName
    public let notes: [FlavorName]
}

/// Something picked on the wheel: a whole category, a group, or a single note.
nonisolated public struct FlavorPath: Hashable, Sendable {
    public let categoryID: String
    public let groupID: String?
    /// The note's Ukrainian name.
    public let note: String?

    public init(category: String, group: String? = nil, note: String? = nil) {
        categoryID = category
        groupID = group
        self.note = note
    }

    /// 1 category, 2 group, 3 note.
    public var level: Int { note != nil ? 3 : (groupID != nil ? 2 : 1) }

    public var category: FlavorCategory? { FlavorTaxonomy.category(categoryID) }
    public var group: FlavorGroup? { groupID.flatMap { id in category?.groups.first { $0.id == id } } }

    /// What's saved with the brew: the deepest name, in Ukrainian.
    public var storedLabel: String {
        note ?? group?.name.uk ?? category?.name.uk ?? categoryID
    }

    /// "Fruit › Tropical › Mango" (a group named like its category isn't repeated).
    public var localizedParts: [String] {
        var parts = [category?.name.localized ?? categoryID]
        if let group, group.name != category?.name { parts.append(group.name.localized) }
        if let note, let name = group?.notes.first(where: { $0.uk == note }) { parts.append(name.localized) }
        return parts
    }
}

nonisolated public extension FlavorTaxonomy {
    static func category(_ id: String) -> FlavorCategory? {
        categories.first { $0.id == id }
    }

    /// The path for a saved label (a note, group or category name, in either language), so a brew's
    /// flavors show on the wheel again when edited. Notes win over same-named groups.
    static func path(forLabel label: String) -> FlavorPath? {
        for category in categories {
            for group in category.groups {
                if let note = group.notes.first(where: { $0.uk == label || $0.en == label }) {
                    return FlavorPath(category: category.id, group: group.id, note: note.uk)
                }
            }
        }
        for category in categories {
            if let group = category.groups.first(where: { $0.name.uk == label || $0.name.en == label }), group.name != category.name {
                return FlavorPath(category: category.id, group: group.id)
            }
            if category.name.uk == label || category.name.en == label {
                return FlavorPath(category: category.id)
            }
        }
        return nil
    }
}
