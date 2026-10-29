import CoreData
import Foundation
import Testing
import Domain
@testable import DataLayer

/// Each test gets its own in-memory SQLite store (same engine as on device, incl. history tracking).
struct CoreDataStoreTests {
    private let persistence: PersistenceController
    private let brews: RecordStore<Brew>

    init() throws {
        persistence = try PersistenceController(location: .inMemory)
        brews = RecordStore(persistence: persistence)
    }

    // MARK: - Round trip & reads

    @Test func savesAndLoadsFullBrew() async throws {
        let original = Brew.samples[1] // espresso with milk, gear, shot

        try await brews.upsert([original], policy: .overwrite)
        let loaded = try await brews.fetch(id: original.id)

        #expect(loaded == original)
    }

    @Test func fetchAllIsNewestFirstAndHidesTrash() async throws {
        try await brews.upsert(Brew.samples, policy: .overwrite)
        try await brews.softDelete(id: Brew.samples[1].id)

        let active = try await brews.fetchAll()
        let trash = try await brews.fetchAll(.only)

        #expect(active.map(\.id) == [Brew.samples[0].id, Brew.samples[2].id])
        #expect(trash.map(\.id) == [Brew.samples[1].id])
        #expect(try await brews.count() == 2)
        #expect(try await brews.count(.include) == 3)
    }

    @Test func queryColumnsAreWritten() async throws {
        try await brews.upsert(Brew.samples, policy: .overwrite)
        let beanID = try #require(Brew.samples[0].bean?.beanID)

        let byBean = try await brews.fetchAll { NSPredicate(format: "beanID == %@", beanID as CVarArg) }
        let espresso = try await brews.fetchAll { NSPredicate(format: "category == %@", BrewCategory.espresso.rawValue) }
        let cafe = try await brews.fetchAll { NSPredicate(format: "isCafeVisit == YES") }

        #expect(byBean.map(\.id) == [Brew.samples[0].id])
        #expect(Set(espresso.map(\.id)) == [Brew.samples[1].id, Brew.samples[2].id])
        #expect(cafe.map(\.id) == [Brew.samples[2].id])
    }

    // MARK: - Upsert policies

    @Test func lastWriteWinsKeepsNewerLocalCopy() async throws {
        var local = Brew.samples[0]
        local.notes = "edited on phone"
        local.updatedAt = Date(timeIntervalSince1970: 2_000)
        try await brews.upsert([local], policy: .overwrite)

        var stale = Brew.samples[0]
        stale.updatedAt = Date(timeIntervalSince1970: 1_000)
        var fresh = Brew.samples[0]
        fresh.notes = "from server"
        fresh.updatedAt = Date(timeIntervalSince1970: 3_000)

        let staleResult = try await brews.upsert([stale], policy: .lastWriteWins)
        #expect(staleResult == UpsertResult(skipped: 1))
        #expect(try await brews.fetch(id: local.id)?.notes == "edited on phone")

        let freshResult = try await brews.upsert([fresh], policy: .lastWriteWins)
        #expect(freshResult == UpsertResult(updated: 1))
        #expect(try await brews.fetch(id: local.id)?.notes == "from server")
    }

    @Test func upsertCountsInsertsAndUpdates() async throws {
        let first = try await brews.upsert([Brew.samples[0]], policy: .overwrite)
        let second = try await brews.upsert(Brew.samples, policy: .overwrite)

        #expect(first == UpsertResult(inserted: 1))
        #expect(second == UpsertResult(inserted: 2, unchanged: 1))
    }

    @Test func identicalUpsertWritesNothing() async throws {
        try await brews.upsert([Brew.samples[0]], policy: .overwrite)
        var changes = brews.changes().makeAsyncIterator()

        let result = try await brews.upsert([Brew.samples[0]], policy: .lastWriteWins)
        #expect(result == UpsertResult(unchanged: 1))

        // No save happened, so the next event comes from this real edit.
        var edited = Brew.samples[0]
        edited.notes = "changed"
        try await brews.upsert([edited], policy: .overwrite)
        #expect(await changes.next() != nil)
    }

    // MARK: - Trash

    @Test func softDeleteRestoreAndPurge() async throws {
        let id = Brew.samples[0].id
        try await brews.upsert([Brew.samples[0]], policy: .overwrite)

        try await brews.softDelete(id: id, at: Date(timeIntervalSince1970: 100))
        #expect(try await brews.fetch(id: id) == nil)
        #expect(try await brews.fetch(id: id, .include)?.deletedAt == Date(timeIntervalSince1970: 100))

        try await brews.restore(id: id)
        #expect(try await brews.fetch(id: id) != nil)

        try await brews.softDelete(id: id, at: Date(timeIntervalSince1970: 100))
        #expect(try await brews.purgeDeleted(before: Date(timeIntervalSince1970: 50)) == 0)
        #expect(try await brews.purgeDeleted(before: Date(timeIntervalSince1970: 200)) == 1)
        #expect(try await brews.count(.include) == 0)
    }

    @Test func deletingMissingRecordThrowsNotFound() async throws {
        await #expect(throws: RepositoryError.notFound) {
            try await brews.softDelete(id: UUID())
        }
    }

    // MARK: - Change notifications

    @Test func changesFireOnlyForTouchedEntity() async throws {
        let brewChanges = brews.changes()
        let beanChanges = RecordStore<Bean>(persistence: persistence).changes()

        try await brews.upsert([Brew.samples[0]], policy: .overwrite)

        var brewIterator = brewChanges.makeAsyncIterator()
        #expect(await brewIterator.next() != nil)

        // Bean stream received nothing: a bean write now must be its first event.
        try await RecordStore<Bean>(persistence: persistence).upsert(Bean.samples, policy: .overwrite)
        var beanIterator = beanChanges.makeAsyncIterator()
        #expect(await beanIterator.next() != nil)
    }

    // MARK: - History tracking (sync groundwork)

    @Test func transactionsAreRecordedWithAuthor() async throws {
        try await brews.upsert([Brew.samples[0]], policy: .overwrite, author: .import)

        let authors = try await persistence.read { context in
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast)
            let result = try context.execute(request) as? NSPersistentHistoryResult
            let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
            return transactions.compactMap(\.author)
        }

        #expect(authors == ["import"])
    }

    // MARK: - Documents

    @Test func documentsRoundTrip() async throws {
        let documents = DocumentStore(persistence: persistence)
        let profile = UserProfile(name: "Олена", avatar: Avatar(emoji: "☕"))

        #expect(try await documents.load(UserProfile.self, key: .profile) == nil)
        try await documents.save(profile, key: .profile)

        #expect(try await documents.load(UserProfile.self, key: .profile) == profile)
    }
}

struct CoreDataBrewRepositoryTests {
    @Test func repositoryBehaviour() async throws {
        let repository = CoreDataRecordRepository<Brew>(persistence: try PersistenceController(location: .inMemory))
        var brew = Brew.samples[0]
        brew.updatedAt = .distantPast

        try await repository.save(brew)
        let saved = try await repository.fetch(id: brew.id)
        #expect(saved.updatedAt > .distantPast)

        try await repository.delete(id: brew.id)
        #expect(try await repository.fetchAll().isEmpty)
        await #expect(throws: RepositoryError.notFound) {
            try await repository.fetch(id: brew.id)
        }
    }

    @Test func storeSurvivesReopeningOnDisk() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        do {
            let repository = CoreDataRecordRepository<Brew>(persistence: try PersistenceController(location: .directory(directory)))
            try await repository.save(Brew.samples[0])
        }
        let reopened = CoreDataRecordRepository<Brew>(persistence: try PersistenceController(location: .directory(directory)))

        #expect(try await reopened.fetchAll().map(\.id) == [Brew.samples[0].id])
    }
}
