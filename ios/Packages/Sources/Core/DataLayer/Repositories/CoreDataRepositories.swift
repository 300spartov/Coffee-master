import CoreData
import Foundation
import Domain

/// Public entry point to the Core Data repositories. The implementations stay internal; the app
/// only sees the Domain protocols.
public enum CoreDataRepositories {
    public static func brews(_ persistence: PersistenceController) -> any BrewRepository {
        CoreDataRecordRepository<Brew>(persistence: persistence)
    }

    public static func trash(_ persistence: PersistenceController) -> any TrashRepository {
        CoreDataRecordRepository<Brew>(persistence: persistence)
    }

    public static func beans(_ persistence: PersistenceController) -> any BeanRepository {
        CoreDataRecordRepository<Bean>(persistence: persistence)
    }

    public static func devices(_ persistence: PersistenceController) -> any DeviceRepository {
        CoreDataRecordRepository<Device>(persistence: persistence)
    }

    public static func filterPacks(_ persistence: PersistenceController) -> any FilterPackRepository {
        CoreDataRecordRepository<FilterPack>(persistence: persistence)
    }

    public static func profile(_ persistence: PersistenceController) -> any ProfileRepository {
        CoreDataProfileRepository(documents: DocumentStore(persistence: persistence))
    }

    public static func suggestions(_ persistence: PersistenceController) -> any SuggestionsRepository {
        CoreDataSuggestionsRepository(documents: DocumentStore(persistence: persistence))
    }
}

/// Core Data repository for any stored record type; specific protocols come from the conditional
/// conformances below (the same shape as `InMemoryRecordRepository`).
struct CoreDataRecordRepository<Record: StoredRecord>: RecordRepository {
    let store: RecordStore<Record>

    init(persistence: PersistenceController) {
        store = RecordStore(persistence: persistence)
    }

    func fetchAll() async throws -> [Record] { try await store.fetchAll() }
    func fetch(id: UUID) async throws -> Record { try await store.require(id: id) }
    func save(_ record: Record) async throws { try await store.save(record) }
    /// Soft delete, with the record's side effects (e.g. a brew returns its coffee to stock).
    func delete(id: UUID) async throws { try await store.softDelete(id: id) }
    func changes() async -> AsyncStream<Void> { store.changes() }
}

// MARK: - Brews & trash

extension CoreDataRecordRepository: BrewRepository where Record == Brew {}

extension CoreDataRecordRepository: TrashRepository where Record == Brew {
    func trashedBrews() async throws -> [Brew] {
        try await store.fetchAll(.only).sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    func restore(brewID: Brew.ID) async throws { try await store.restore(id: brewID) }
    func deletePermanently(brewID: Brew.ID) async throws { try await store.deletePermanently(id: brewID) }
    func emptyTrash() async throws { try await store.purgeDeleted(before: .distantFuture) }

    @discardableResult
    func purgeExpired(now: Date) async throws -> Int {
        try await store.purgeDeleted(before: TrashPolicy.expiryDate(now: now))
    }
}

// MARK: - Inventory

extension CoreDataRecordRepository: BeanRepository where Record == Bean {
    @discardableResult
    func consume(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try await store.mutate(id: beanID) { $0.consume(grams: grams) }
    }

    @discardableResult
    func restock(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try await store.mutate(id: beanID) { $0.restock(grams: grams) }
    }
}

extension CoreDataRecordRepository: DeviceRepository where Record == Device {
    func fetchAll(of type: DeviceType) async throws -> [Device] {
        let rawType = type.rawValue
        return try await store.fetchAll { NSPredicate(format: "%K == %@", CoreDataModel.Attribute.type, rawType) }
    }

    func contains(name: String, type: DeviceType) async throws -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await fetchAll(of: type).contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}

extension CoreDataRecordRepository: FilterPackRepository where Record == FilterPack {
    @discardableResult
    func use(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try await store.mutate(id: packID) { $0.use(count: count) }
    }

    @discardableResult
    func putBack(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try await store.mutate(id: packID) { $0.putBack(count: count) }
    }
}

// MARK: - Profile & suggestions (singleton documents)

struct CoreDataProfileRepository: ProfileRepository {
    let documents: DocumentStore

    func profile() async throws -> UserProfile {
        try await documents.load(UserProfile.self, key: .profile) ?? UserProfile()
    }

    func saveProfile(_ profile: UserProfile) async throws {
        var profile = profile
        profile.updatedAt = .now
        try await documents.save(profile, key: .profile, updatedAt: profile.updatedAt)
    }

    func earnedAchievements() async throws -> [EarnedAchievement] {
        try await documents.load([EarnedAchievement].self, key: .achievements) ?? []
    }

    @discardableResult
    func recordAchievements(_ achievements: [EarnedAchievement]) async throws -> [EarnedAchievement] {
        try await documents.persistence.write { context in
            let current = try DocumentStore.load([EarnedAchievement].self, key: .achievements, in: context) ?? []
            let merged = EarnedAchievement.merge(current, achievements)
            guard merged != current else { return [] }
            try DocumentStore.save(merged, key: .achievements, updatedAt: .now, in: context)
            let known = Set(current.map(\.achievementID))
            return merged.filter { !known.contains($0.achievementID) }
        }
    }

    func changes() async -> AsyncStream<Void> { documents.changes() }
}

struct CoreDataSuggestionsRepository: SuggestionsRepository {
    let documents: DocumentStore

    func suggestions() async throws -> Suggestions {
        try await documents.load(Suggestions.self, key: .suggestions) ?? Suggestions()
    }

    func remember(_ additions: Suggestions) async throws {
        try await documents.persistence.write { context in
            let current = try DocumentStore.load(Suggestions.self, key: .suggestions, in: context) ?? Suggestions()
            let merged = current.merging(additions)
            guard merged != current else { return }
            try DocumentStore.save(merged, key: .suggestions, updatedAt: .now, in: context)
        }
    }
}
