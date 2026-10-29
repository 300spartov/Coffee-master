import Foundation

/// The user's profile and unlocked achievements (singletons, not lists).
public protocol ProfileRepository: Sendable {
    /// Empty profile if none was saved yet.
    func profile() async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
    /// Oldest first.
    func earnedAchievements() async throws -> [EarnedAchievement]
    /// Adds unlocks, keeping the earliest date per achievement. Returns only the newly added ones.
    @discardableResult
    func recordAchievements(_ achievements: [EarnedAchievement]) async throws -> [EarnedAchievement]
    func changes() async -> AsyncStream<Void>
}

/// Autocomplete values remembered from earlier input.
public protocol SuggestionsRepository: Sendable {
    func suggestions() async throws -> Suggestions
    /// Remembers non-empty values (case-insensitive, no duplicates).
    func remember(_ additions: Suggestions) async throws
}
