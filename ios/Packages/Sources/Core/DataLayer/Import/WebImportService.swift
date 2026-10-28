import Foundation
import AppCore
import Domain
import WebImport

/// What an import did, for the confirmation toast and logs.
public struct WebImportSummary: Equatable, Sendable {
    public var brews = UpsertResult()
    public var beans = UpsertResult()
    public var devices = UpsertResult()
    public var filterPacks = UpsertResult()
    public var achievementsAdded = 0
    public var profileImported = false

    /// Records that were created or changed (excludes ones where the local copy was newer).
    public var changedCount: Int {
        [brews, beans, devices, filterPacks].reduce(0) { $0 + $1.inserted + $1.updated } + achievementsAdded
    }
}

/// Saves a web app export (D2) into the local store.
///
/// - One transaction, authored `.import`: all or nothing.
/// - Safe to repeat: web records map to stable UUIDs, and `lastWriteWins` keeps anything
///   edited locally after a previous import.
/// - Profile is taken only if the local one is empty; achievements and suggestions are merged.
public struct WebImportService: Sendable {
    private let persistence: PersistenceController

    public init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    /// Decodes and saves a `.json` export. Throws `WebImportError` for unreadable files.
    @discardableResult
    public func importJSON(_ data: Data, importedAt: Date = .now) async throws -> WebImportSummary {
        let decoded = try WebImporter.decode(data, importedAt: importedAt)
        return try await save(decoded)
    }

    @discardableResult
    public func save(_ data: WebImport) async throws -> WebImportSummary {
        let summary = try await persistence.write(author: .import) { context in
            var summary = WebImportSummary()
            summary.brews = try RecordStore<Brew>.upsert(data.brews, policy: .lastWriteWins, in: context)
            summary.beans = try RecordStore<Bean>.upsert(data.beans, policy: .lastWriteWins, in: context)
            summary.devices = try RecordStore<Device>.upsert(data.devices, policy: .lastWriteWins, in: context)
            summary.filterPacks = try RecordStore<FilterPack>.upsert(data.filterPacks, policy: .lastWriteWins, in: context)

            if let profile = data.profile {
                let local = try DocumentStore.load(UserProfile.self, key: .profile, in: context)
                if local == nil || local?.name.isEmpty == true {
                    try DocumentStore.save(profile, key: .profile, updatedAt: profile.updatedAt, in: context)
                    summary.profileImported = true
                }
            }

            let localAchievements = try DocumentStore.load([EarnedAchievement].self, key: .achievements, in: context) ?? []
            let mergedAchievements = Self.merge(localAchievements, data.achievements)
            summary.achievementsAdded = mergedAchievements.count - localAchievements.count
            if summary.achievementsAdded > 0 {
                try DocumentStore.save(mergedAchievements, key: .achievements, updatedAt: .now, in: context)
            }

            let localSuggestions = try DocumentStore.load(Suggestions.self, key: .suggestions, in: context) ?? Suggestions()
            let mergedSuggestions = Self.merge(localSuggestions, data.suggestions)
            if mergedSuggestions != localSuggestions {
                try DocumentStore.save(mergedSuggestions, key: .suggestions, updatedAt: .now, in: context)
            }
            return summary
        }
        Log.data.info("Web import: \(summary.changedCount) changed, brews \(summary.brews.inserted)+\(summary.brews.updated), skipped \(summary.brews.skipped)")
        return summary
    }

    /// Union by id, keeping the earliest unlock date.
    static func merge(_ local: [EarnedAchievement], _ imported: [EarnedAchievement]) -> [EarnedAchievement] {
        var byID = Dictionary(local.map { ($0.achievementID, $0) }, uniquingKeysWith: { min($0, $1, by: \.earnedAt) })
        for achievement in imported {
            if let existing = byID[achievement.achievementID] {
                byID[achievement.achievementID] = min(existing, achievement, by: \.earnedAt)
            } else {
                byID[achievement.achievementID] = achievement
            }
        }
        return byID.values.sorted { $0.earnedAt < $1.earnedAt }
    }

    static func merge(_ local: Suggestions, _ imported: Suggestions) -> Suggestions {
        func union(_ a: [String], _ b: [String]) -> [String] {
            b.reduce(a) { Suggestions.adding($1, to: $0) }
        }
        return Suggestions(
            roasters: union(local.roasters, imported.roasters),
            beanNames: union(local.beanNames, imported.beanNames),
            milks: union(local.milks, imported.milks),
            mixers: union(local.mixers, imported.mixers)
        )
    }
}

private func min<T>(_ a: T, _ b: T, by key: KeyPath<T, Date>) -> T {
    a[keyPath: key] <= b[keyPath: key] ? a : b
}
