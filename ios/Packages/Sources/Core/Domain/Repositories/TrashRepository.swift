import Foundation

/// Deleted brews. Kept for `TrashPolicy.retention`, then purged (web app: 30 days).
public protocol TrashRepository: Sendable {
    /// Most recently deleted first.
    func trashedBrews() async throws -> [Brew]
    /// Brings a brew back and takes its coffee and filter from stock again.
    func restore(brewID: Brew.ID) async throws
    func deletePermanently(brewID: Brew.ID) async throws
    func emptyTrash() async throws
    /// Removes brews deleted more than `TrashPolicy.retention` before `now`. Returns how many.
    @discardableResult
    func purgeExpired(now: Date) async throws -> Int
    func changes() async -> AsyncStream<Void>
}

public enum TrashPolicy {
    public static let retention: TimeInterval = 30 * 24 * 60 * 60

    public static func expiryDate(now: Date = .now) -> Date {
        now.addingTimeInterval(-retention)
    }
}
