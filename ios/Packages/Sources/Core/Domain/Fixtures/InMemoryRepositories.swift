import Foundation
import os

// Thread-safe in-memory repositories. They are the DI defaults (SwiftUI previews and package
// tests work without setup) and handy test doubles. They don't model cross-entity effects
// (e.g. deleting a brew doesn't restock its bean) — that's the Core Data implementation's job.

/// Generic in-memory store for any `Syncable` record, with soft delete and change notifications.
/// Specific repository protocols are added through conditional conformances below.
public final class InMemoryRecordRepository<Record: Syncable>: RecordRepository, Sendable {
    private let storage: OSAllocatedUnfairLock<[UUID: Record]>
    private let broadcaster = ChangeBroadcaster()
    private let areInIncreasingOrder: @Sendable (Record, Record) -> Bool

    public init(_ records: [Record] = [], sortedBy areInIncreasingOrder: @escaping @Sendable (Record, Record) -> Bool) {
        storage = OSAllocatedUnfairLock(initialState: Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { $1 }))
        self.areInIncreasingOrder = areInIncreasingOrder
    }

    // MARK: RecordRepository

    public func fetchAll() async throws -> [Record] {
        records(.exclude)
    }

    public func fetch(id: UUID) async throws -> Record {
        guard let record = storage.withLock({ $0[id] }), !record.isDeleted else {
            throw RepositoryError.notFound
        }
        return record
    }

    public func save(_ record: Record) async throws {
        var record = record
        record.touch()
        let saved = record
        write { $0[saved.id] = saved }
    }

    public func delete(id: UUID) async throws {
        try mutate(id: id) { $0.markDeleted() }
    }

    public func changes() async -> AsyncStream<Void> {
        broadcaster.stream()
    }

    // MARK: Helpers for the conditional conformances

    func records(_ filter: DeletedFilter) -> [Record] {
        storage.withLock { $0.values.filter(filter.matches) }.sorted(by: areInIncreasingOrder)
    }

    /// Changes one record matching `filter`. Throws `notFound` otherwise.
    @discardableResult
    func mutate(id: UUID, _ filter: DeletedFilter = .exclude, _ change: (inout Record) -> Void) throws -> Record {
        try write { records in
            guard var record = records[id], filter.matches(record) else { throw RepositoryError.notFound }
            change(&record)
            records[id] = record
            return record
        }
    }

    @discardableResult
    func removeAll(where shouldRemove: (Record) -> Bool) -> Int {
        write { records in
            let ids = records.values.filter(shouldRemove).map(\.id)
            ids.forEach { records.removeValue(forKey: $0) }
            return ids.count
        }
    }

    private func write<T>(_ body: (inout [UUID: Record]) throws -> T) rethrows -> T {
        let result = try storage.withLockUnchecked { try body(&$0) }
        broadcaster.notify()
        return result
    }
}

// MARK: - Brews & trash

extension InMemoryRecordRepository: BrewRepository where Record == Brew {
    public convenience init(brews: [Brew]) {
        self.init(brews) { $0.date > $1.date }
    }
}

extension InMemoryRecordRepository: TrashRepository where Record == Brew {
    public func trashedBrews() async throws -> [Brew] {
        records(.only).sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    public func restore(brewID: Brew.ID) async throws {
        try mutate(id: brewID, .only) { $0.restore() }
    }

    public func deletePermanently(brewID: Brew.ID) async throws {
        guard removeAll(where: { $0.id == brewID && $0.isDeleted }) > 0 else { throw RepositoryError.notFound }
    }

    public func emptyTrash() async throws {
        removeAll { $0.isDeleted }
    }

    @discardableResult
    public func purgeExpired(now: Date) async throws -> Int {
        let expiry = TrashPolicy.expiryDate(now: now)
        return removeAll { ($0.deletedAt ?? .distantFuture) < expiry }
    }
}

// MARK: - Inventory

extension InMemoryRecordRepository: BeanRepository where Record == Bean {
    public convenience init(beans: [Bean]) {
        self.init(beans) { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    public func consume(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try mutate(id: beanID) { $0.consume(grams: grams) }
    }

    @discardableResult
    public func restock(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try mutate(id: beanID) { $0.restock(grams: grams) }
    }
}

extension InMemoryRecordRepository: DeviceRepository where Record == Device {
    public convenience init(devices: [Device]) {
        self.init(devices) { ($0.type.rawValue, $0.name) < ($1.type.rawValue, $1.name) }
    }

    public func fetchAll(of type: DeviceType) async throws -> [Device] {
        records(.exclude).filter { $0.type == type }
    }

    public func contains(name: String, type: DeviceType) async throws -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return records(.exclude).contains { $0.type == type && $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}

extension InMemoryRecordRepository: FilterPackRepository where Record == FilterPack {
    public convenience init(filterPacks: [FilterPack]) {
        self.init(filterPacks) { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    public func use(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try mutate(id: packID) { $0.use(count: count) }
    }

    @discardableResult
    public func putBack(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try mutate(id: packID) { $0.putBack(count: count) }
    }
}

// MARK: - Profile & suggestions

public final class InMemoryProfileRepository: ProfileRepository, Sendable {
    private struct State: Sendable {
        var profile = UserProfile()
        var achievements: [EarnedAchievement] = []
    }

    private let state: OSAllocatedUnfairLock<State>
    private let broadcaster = ChangeBroadcaster()

    public init(profile: UserProfile = UserProfile(), achievements: [EarnedAchievement] = []) {
        state = OSAllocatedUnfairLock(initialState: State(profile: profile, achievements: achievements))
    }

    public func profile() async throws -> UserProfile { state.withLock { $0.profile } }

    public func saveProfile(_ profile: UserProfile) async throws {
        var updated = profile
        updated.updatedAt = .now
        let saved = updated
        state.withLock { $0.profile = saved }
        broadcaster.notify()
    }

    public func earnedAchievements() async throws -> [EarnedAchievement] { state.withLock { $0.achievements } }

    @discardableResult
    public func recordAchievements(_ achievements: [EarnedAchievement]) async throws -> [EarnedAchievement] {
        let added = state.withLock { state in
            let known = Set(state.achievements.map(\.achievementID))
            state.achievements = EarnedAchievement.merge(state.achievements, achievements)
            return state.achievements.filter { !known.contains($0.achievementID) }
        }
        if !added.isEmpty { broadcaster.notify() }
        return added
    }

    public func changes() async -> AsyncStream<Void> { broadcaster.stream() }
}

public final class InMemorySuggestionsRepository: SuggestionsRepository, Sendable {
    private let state: OSAllocatedUnfairLock<Suggestions>

    public init(_ suggestions: Suggestions = Suggestions()) {
        state = OSAllocatedUnfairLock(initialState: suggestions)
    }

    public func suggestions() async throws -> Suggestions { state.withLock { $0 } }

    public func remember(_ additions: Suggestions) async throws {
        state.withLock { $0 = $0.merging(additions) }
    }
}
