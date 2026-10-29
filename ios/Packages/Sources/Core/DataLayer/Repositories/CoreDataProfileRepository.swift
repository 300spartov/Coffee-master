import Foundation
import Domain

public struct CoreDataProfileRepository: ProfileRepository {
    private let documents: DocumentStore

    public init(persistence: PersistenceController) {
        documents = DocumentStore(persistence: persistence)
    }

    public func profile() async throws -> UserProfile {
        try await documents.load(UserProfile.self, key: .profile) ?? UserProfile()
    }

    public func saveProfile(_ profile: UserProfile) async throws {
        var profile = profile
        profile.updatedAt = .now
        try await documents.save(profile, key: .profile, updatedAt: profile.updatedAt)
    }

    public func earnedAchievements() async throws -> [EarnedAchievement] {
        try await documents.load([EarnedAchievement].self, key: .achievements) ?? []
    }

    @discardableResult
    public func recordAchievements(_ achievements: [EarnedAchievement]) async throws -> [EarnedAchievement] {
        try await documents.persistence.write { context in
            let current = try DocumentStore.load([EarnedAchievement].self, key: .achievements, in: context) ?? []
            let merged = EarnedAchievement.merge(current, achievements)
            guard merged != current else { return [] }
            try DocumentStore.save(merged, key: .achievements, updatedAt: .now, in: context)
            let known = Set(current.map(\.achievementID))
            return merged.filter { !known.contains($0.achievementID) }
        }
    }

    public func changes() async -> AsyncStream<Void> { documents.changes() }
}
