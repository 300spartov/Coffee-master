import Foundation
import Testing
import Domain
@testable import DataLayer

/// Core Data repositories on an in-memory SQLite store.
struct RepositoriesTests {
    private let persistence: PersistenceController
    private let brews: CoreDataRecordRepository<Brew>
    private let beans: CoreDataRecordRepository<Bean>
    private let filters: CoreDataRecordRepository<FilterPack>
    private var trash: CoreDataRecordRepository<Brew> { brews }

    init() throws {
        persistence = try PersistenceController(location: .inMemory)
        brews = CoreDataRecordRepository(persistence: persistence)
        beans = CoreDataRecordRepository(persistence: persistence)
        filters = CoreDataRecordRepository(persistence: persistence)
    }

    /// A V60 brew using `bean` (15 g) and one filter from `pack`.
    private func seedBrewUsingStock() async throws -> (brew: Brew, bean: Bean, pack: FilterPack) {
        let bean = Bean(name: "Kenya", totalGrams: 250, remainingGrams: 100)
        let pack = FilterPack(name: "Cafec", total: 100, remaining: 10)
        let brew = Brew(
            method: .v60,
            bean: BeanReference(beanID: bean.id, name: bean.name),
            filter: GearReference(id: pack.id, name: pack.name),
            doseGrams: 15,
            ratio: 16,
            rating: 8
        )
        try await beans.save(bean)
        try await filters.save(pack)
        try await brews.save(brew)
        return (brew, bean, pack)
    }

    // MARK: - Brew delete ↔ stock

    @Test func deletingBrewReturnsCoffeeAndFilterToStock() async throws {
        let (brew, bean, pack) = try await seedBrewUsingStock()

        try await brews.delete(id: brew.id)

        #expect(try await beans.fetch(id: bean.id).remainingGrams == 115)
        #expect(try await filters.fetch(id: pack.id).remaining == 11)
        #expect(try await brews.fetchAll().isEmpty)
        #expect(try await trash.trashedBrews().map(\.id) == [brew.id])
    }

    @Test func restoringBrewTakesStockAgain() async throws {
        let (brew, bean, pack) = try await seedBrewUsingStock()
        try await brews.delete(id: brew.id)

        try await trash.restore(brewID: brew.id)

        #expect(try await beans.fetch(id: bean.id).remainingGrams == 100)
        #expect(try await filters.fetch(id: pack.id).remaining == 10)
        #expect(try await brews.fetchAll().map(\.id) == [brew.id])
        #expect(try await trash.trashedBrews().isEmpty)
    }

    @Test func deletingBrewWhoseBeanIsGoneStillWorks() async throws {
        let (brew, bean, _) = try await seedBrewUsingStock()
        try await beans.delete(id: bean.id)

        try await brews.delete(id: brew.id)

        #expect(try await trash.trashedBrews().map(\.id) == [brew.id])
    }

    @Test func restoringActiveBrewIsNotFound() async throws {
        let (brew, _, _) = try await seedBrewUsingStock()

        await #expect(throws: RepositoryError.notFound) {
            try await trash.restore(brewID: brew.id)
        }
    }

    // MARK: - Trash lifecycle

    @Test func purgeRemovesOnlyExpired() async throws {
        let now = Date(timeIntervalSince1970: 100 * 86_400)
        var old = Brew.samples[0]
        old.markDeleted(at: now.addingTimeInterval(-31 * 86_400))
        var recent = Brew.samples[1]
        recent.markDeleted(at: now.addingTimeInterval(-29 * 86_400))
        try await RecordStore<Brew>(persistence: persistence).upsert([old, recent, Brew.samples[2]], policy: .overwrite)

        let purged = try await trash.purgeExpired(now: now)

        #expect(purged == 1)
        #expect(try await trash.trashedBrews().map(\.id) == [recent.id])
        #expect(try await brews.fetchAll().map(\.id) == [Brew.samples[2].id])
    }

    @Test func deletePermanentlyAndEmptyTrash() async throws {
        for brew in Brew.samples { try await brews.save(brew) }
        for brew in Brew.samples { try await brews.delete(id: brew.id) }

        try await trash.deletePermanently(brewID: Brew.samples[0].id)
        #expect(try await trash.trashedBrews().count == 2)

        await #expect(throws: RepositoryError.notFound) {
            try await trash.deletePermanently(brewID: UUID())
        }

        try await trash.emptyTrash()
        #expect(try await trash.trashedBrews().isEmpty)
    }

    @Test func trashIsMostRecentlyDeletedFirst() async throws {
        for brew in Brew.samples { try await brews.save(brew) }
        try await brews.delete(id: Brew.samples[2].id)
        try await Task.sleep(for: .milliseconds(5))
        try await brews.delete(id: Brew.samples[0].id)

        #expect(try await trash.trashedBrews().map(\.id) == [Brew.samples[0].id, Brew.samples[2].id])
    }

    // MARK: - Inventory

    @Test func beanConsumeAndRestock() async throws {
        let bean = Bean(name: "Kenya", totalGrams: 250, remainingGrams: 20)
        try await beans.save(bean)

        #expect(try await beans.consume(beanID: bean.id, grams: 30).remainingGrams == 0)
        #expect(try await beans.restock(beanID: bean.id, grams: 500).remainingGrams == 250)
        await #expect(throws: RepositoryError.notFound) {
            try await beans.consume(beanID: UUID(), grams: 1)
        }
    }

    @Test func devicesByTypeAndDuplicateCheck() async throws {
        let devices = CoreDataRecordRepository<Device>(persistence: persistence)
        for device in Device.samples { try await devices.save(device) }

        #expect(try await devices.fetchAll().count == Device.samples.count)
        #expect(try await devices.fetchAll(of: .dripper).map(\.name) == ["AeroPress Original", "Hario V60 02"])
        #expect(try await devices.contains(name: "  hario v60 02 ", type: .dripper))
        #expect(try await !devices.contains(name: "Hario V60 02", type: .grinder))

        try await devices.delete(id: Device.samples[0].id)
        #expect(try await !devices.contains(name: "Hario V60 02", type: .dripper))
    }

    @Test func filterPackUseAndPutBack() async throws {
        let pack = FilterPack(name: "Cafec", total: 100, remaining: 1)
        try await filters.save(pack)

        #expect(try await filters.use(packID: pack.id, count: 1).isEmpty)
        #expect(try await filters.putBack(packID: pack.id, count: 2).remaining == 2)
    }

    // MARK: - Profile & suggestions

    @Test func profileDefaultsToEmptyAndSaves() async throws {
        let profiles = CoreDataProfileRepository(documents: DocumentStore(persistence: persistence))

        #expect(try await profiles.profile().name.isEmpty)
        try await profiles.saveProfile(UserProfile(name: "Олена", location: "Київ"))
        #expect(try await profiles.profile().location == "Київ")
    }

    @Test func recordAchievementsReturnsOnlyNewOnes() async throws {
        let profiles = CoreDataProfileRepository(documents: DocumentStore(persistence: persistence))
        let first = EarnedAchievement(achievementID: "brew_1", earnedAt: Date(timeIntervalSince1970: 100))
        let second = EarnedAchievement(achievementID: "streak_7", earnedAt: Date(timeIntervalSince1970: 200))

        #expect(try await profiles.recordAchievements([first]) == [first])
        #expect(try await profiles.recordAchievements([first, second]) == [second])
        #expect(try await profiles.recordAchievements([first]).isEmpty)
        #expect(try await profiles.earnedAchievements() == [first, second])
    }

    @Test func suggestionsAccumulateWithoutDuplicates() async throws {
        let suggestions = CoreDataSuggestionsRepository(documents: DocumentStore(persistence: persistence))

        try await suggestions.remember(Suggestions(roasters: ["Penyora"], milks: ["Oat"]))
        try await suggestions.remember(Suggestions(roasters: ["penyora", "Wonder&Full"]))

        let stored = try await suggestions.suggestions()
        #expect(stored.roasters == ["Penyora", "Wonder&Full"])
        #expect(stored.milks == ["Oat"])
    }

    // MARK: - Change notifications across entities

    @Test func deletingBrewNotifiesBeanObservers() async throws {
        let (brew, _, _) = try await seedBrewUsingStock()
        var beanChanges = await beans.changes().makeAsyncIterator()

        try await brews.delete(id: brew.id)

        #expect(await beanChanges.next() != nil)
    }
}
