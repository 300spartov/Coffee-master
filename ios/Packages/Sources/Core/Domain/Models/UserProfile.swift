import Foundation

/// The signed-in user's public profile. One per account.
public struct UserProfile: Hashable, Codable, Sendable {
    public var name: String
    public var location: String
    /// Self-chosen title, e.g. "Бариста", "Любитель кави".
    public var title: String
    /// Free-text coffee experience ("2 роки").
    public var experience: String
    public var avatar: Avatar
    public var updatedAt: Date

    public init(
        name: String = "",
        location: String = "",
        title: String = "",
        experience: String = "",
        avatar: Avatar = Avatar(),
        updatedAt: Date = .now
    ) {
        self.name = name
        self.location = location
        self.title = title
        self.experience = experience
        self.avatar = avatar
        self.updatedAt = updatedAt
    }

    /// First letter of the name, used when no emoji avatar is set.
    public var initials: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }
}

public struct Avatar: Hashable, Codable, Sendable {
    public var emoji: String?
    /// Background color as `#RRGGBB`.
    public var colorHex: String?

    public init(emoji: String? = nil, colorHex: String? = nil) {
        self.emoji = emoji
        self.colorHex = colorHex
    }
}

/// An unlocked achievement. Definitions (thresholds, XP) live in the gamification logic, not in data.
public struct EarnedAchievement: Hashable, Codable, Sendable, Identifiable {
    public let achievementID: String
    public let earnedAt: Date

    public init(achievementID: String, earnedAt: Date) {
        self.achievementID = achievementID
        self.earnedAt = earnedAt
    }

    public var id: String { achievementID }

    /// Union by id, keeping the earliest unlock date; sorted oldest first.
    public static func merge(_ lhs: [EarnedAchievement], _ rhs: [EarnedAchievement]) -> [EarnedAchievement] {
        var byID = [String: EarnedAchievement]()
        for achievement in lhs + rhs {
            if let existing = byID[achievement.achievementID], existing.earnedAt <= achievement.earnedAt { continue }
            byID[achievement.achievementID] = achievement
        }
        return byID.values.sorted { ($0.earnedAt, $0.achievementID) < ($1.earnedAt, $1.achievementID) }
    }
}

/// Values the user has typed before, offered as autocomplete.
public struct Suggestions: Hashable, Codable, Sendable {
    public var roasters: [String]
    public var beanNames: [String]
    public var milks: [String]
    /// Juices, tonic, etc. for cold espresso drinks.
    public var mixers: [String]

    public init(roasters: [String] = [], beanNames: [String] = [], milks: [String] = [], mixers: [String] = []) {
        self.roasters = roasters
        self.beanNames = beanNames
        self.milks = milks
        self.mixers = mixers
    }

    /// Union of both, keeping this instance's order and appending new values.
    public func merging(_ other: Suggestions) -> Suggestions {
        func union(_ a: [String], _ b: [String]) -> [String] { b.reduce(a) { Suggestions.adding($1, to: $0) } }
        return Suggestions(
            roasters: union(roasters, other.roasters),
            beanNames: union(beanNames, other.beanNames),
            milks: union(milks, other.milks),
            mixers: union(mixers, other.mixers)
        )
    }

    /// Adds without duplicates (case-insensitive), ignoring blanks. Returns the updated list.
    public static func adding(_ value: String, to list: [String]) -> [String] {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !list.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        else { return list }
        return list + [trimmed]
    }
}
