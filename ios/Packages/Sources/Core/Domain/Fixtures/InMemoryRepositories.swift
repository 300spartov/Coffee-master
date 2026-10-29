import Foundation
import os

// Thread-safe in-memory repositories. They are the DI defaults (SwiftUI previews and package
// tests work without setup) and handy test doubles. They don't model cross-entity effects
// (e.g. deleting a brew doesn't restock its bean) — that's the Core Data implementation's job.

/// Generic in-memory store for any `Syncable` record, with soft delete and change notifications.
/// Specific repository protocols are added through conditional conformances below.
public final class InMemoryRecordRepository<Record: Syncable>: RecordRepository, @unchecked Sendable {
    // @unchecked: all mutable state is behind `state`'s lock.
    private struct State {
        var records: [UUID: Record]
        var observers: [UUID: AsyncStream<Void>.Continuation] = [:]
    }

    private let state: OSAllocatedUnfairLock<State>
    private let areInIncreasingOrder: @Sendable (Record, Record) -> Bool

    public init(_ records: [Record] = [], sortedBy areInIncreasingOrder: @escaping @Sendable (Record, Record) -> Bool) {
        state = OSAllocatedUnfairLock(uncheckedState: State(records: Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { $1 })))
        self.areInIncreasingOrder = areInIncreasingOrder
    }

    // MARK: RecordRepository

    public func fetchAll() async throws -> [Record] {
        records(deleted: false)
    }

    public func fetch(id: UUID) async throws -> Record {
        guard let record = state.withLockUnchecked({ $0.records[id] }), !record.isDeleted else {
            throw RepositoryError.notFound
        }
        return record
    }

    public func save(_ record: Record) async throws {
        var record = record
        record.touch()
        write { $0.records[record.id] = record }
    }

    public func delete(id: UUID) async throws {
        try mutate(id: id) { $0.markDeleted() }
    }

    public func changes() async -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let token = UUID()
        state.withLockUnchecked { $0.observers[token] = continuation }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLockUnchecked { _ = $0.observers.removeValue(forKey: token) }
        }
        return stream
    }

    // MARK: Helpers for the conditional conformances

    func records(deleted: Bool) -> [Record] {
        state.withLockUnchecked { $0.records.values.filter { $0.isDeleted == deleted } }.sorted(by: areInIncreasingOrder)
    }

    @discardableResult
    func mutate(id: UUID, includeDeleted: Bool = false, _ change: (inout Record) -> Void) throws -> Record {
        let updated: Record = try write { state in
            guard var record = state.records[id], includeDeleted || !record.isDeleted else {
                throw RepositoryError.notFound
            }
            change(&record)
            state.records[id] = record
            return record
        }
        return updated
    }

    @discardableResult
    func removeAll(where shouldRemove: (Record) -> Bool) -> Int {
        write { state in
            let ids = state.records.values.filter(shouldRemove).map(\.id)
            ids.forEach { state.records.removeValue(forKey: $0) }
            return ids.count
        }
    }

    private func write<T>(_ body: (inout State) throws -> T) rethrows -> T {
        let (result, observers) = try state.withLockUnchecked { state in
            (try body(&state), Array(state.observers.values))
        }
        observers.forEach { $0.yield() }
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
        records(deleted: true).sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    public func restore(brewID: Brew.ID) async throws {
        try mutate(id: brewID, includeDeleted: true) { $0.restore() }
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
        records(deleted: false).filter { $0.type == type }
    }

    public func contains(name: String, type: DeviceType) async throws -> Bool {
        records(deleted: false).contains { $0.type == type && $0.name.caseInsensitiveCompare(name) == .orderedSame }
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

    public init(profile: UserProfile = UserProfile(), achievements: [EarnedAchievement] = []) {
        state = OSAllocatedUnfairLock(initialState: State(profile: profile, achievements: achievements))
    }

    public func profile() async throws -> UserProfile { state.withLock { $0.profile } }

    public func saveProfile(_ profile: UserProfile) async throws {
        var updated = profile
        updated.updatedAt = .now
        let saved = updated
        state.withLock { $0.profile = saved }
    }

    public func earnedAchievements() async throws -> [EarnedAchievement] { state.withLock { $0.achievements } }

    @discardableResult
    public func recordAchievements(_ achievements: [EarnedAchievement]) async throws -> [EarnedAchievement] {
        state.withLock { state in
            let known = Set(state.achievements.map(\.achievementID))
            state.achievements = EarnedAchievement.merge(state.achievements, achievements)
            return state.achievements.filter { !known.contains($0.achievementID) }
        }
    }

    public func changes() async -> AsyncStream<Void> { AsyncStream { _ in } }
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
