import Foundation
import Testing
@testable import Domain

struct InMemoryRepositoryTests {
    @Test func brewsAreNewestFirstAndDeleteMovesToTrash() async throws {
        let repository = InMemoryRecordRepository(brews: Brew.samples.reversed())

        #expect(try await repository.fetchAll().map(\.id) == Brew.samples.map(\.id))

        try await repository.delete(id: Brew.samples[0].id)
        #expect(try await repository.fetchAll().count == 2)
        #expect(try await repository.trashedBrews().map(\.id) == [Brew.samples[0].id])
        await #expect(throws: RepositoryError.notFound) {
            try await repository.fetch(id: Brew.samples[0].id)
        }

        try await repository.restore(brewID: Brew.samples[0].id)
        #expect(try await repository.fetchAll().count == 3)
    }

    @Test func purgeExpiredUsesRetention() async throws {
        let now = Date(timeIntervalSince1970: 100 * 86_400)
        var old = Brew.samples[0]
        old.markDeleted(at: now.addingTimeInterval(-TrashPolicy.retention - 1))
        var recent = Brew.samples[1]
        recent.markDeleted(at: now.addingTimeInterval(-60))
        let repository = InMemoryRecordRepository(brews: [old, recent, Brew.samples[2]])

        #expect(try await repository.purgeExpired(now: now) == 1)
        #expect(try await repository.trashedBrews().map(\.id) == [recent.id])
    }

    @Test func saveStampsUpdatedAtAndNotifies() async throws {
        let repository = InMemoryRecordRepository(beans: [])
        var changes = await repository.changes().makeAsyncIterator()
        var bean = Bean(name: "Kenya")
        bean.updatedAt = .distantPast

        try await repository.save(bean)

        #expect(try await repository.fetch(id: bean.id).updatedAt > .distantPast)
        #expect(await changes.next() != nil)
    }

    @Test func inventoryOperations() async throws {
        let beans = InMemoryRecordRepository(beans: [Bean(id: .fixture(1), name: "Kenya", totalGrams: 250, remainingGrams: 10)])
        let devices = InMemoryRecordRepository(devices: Device.samples)
        let packs = InMemoryRecordRepository(filterPacks: FilterPack.samples)

        #expect(try await beans.consume(beanID: .fixture(1), grams: 15).remainingGrams == 0)
        #expect(try await devices.contains(name: "comandante c40 mk4", type: .grinder))
        #expect(try await devices.fetchAll(of: .kettle).map(\.name) == ["Fellow Stagg EKG"])
        #expect(try await packs.use(packID: FilterPack.samples[1].id, count: 1).remaining == 7)
    }

    @Test func profileAndSuggestions() async throws {
        let profiles = InMemoryProfileRepository()
        let unlock = EarnedAchievement(achievementID: "brew_1", earnedAt: Date(timeIntervalSince1970: 1))
        #expect(try await profiles.recordAchievements([unlock]) == [unlock])
        #expect(try await profiles.recordAchievements([unlock]).isEmpty)

        let suggestions = InMemorySuggestionsRepository()
        try await suggestions.remember(Suggestions(milks: ["Oat", "oat"]))
        #expect(try await suggestions.suggestions().milks == ["Oat"])
    }
}

struct MergeTests {
    @Test func achievementsMergeKeepsEarliest() {
        let early = EarnedAchievement(achievementID: "a", earnedAt: Date(timeIntervalSince1970: 1))
        let late = EarnedAchievement(achievementID: "a", earnedAt: Date(timeIntervalSince1970: 9))
        let other = EarnedAchievement(achievementID: "b", earnedAt: Date(timeIntervalSince1970: 5))

        #expect(EarnedAchievement.merge([late], [early, other]) == [early, other])
    }

    @Test func suggestionsMergeKeepsOrderAndDeduplicates() {
        let merged = Suggestions(roasters: ["B", "A"]).merging(Suggestions(roasters: ["a", "C"], mixers: ["Tonic"]))

        #expect(merged.roasters == ["B", "A", "C"])
        #expect(merged.mixers == ["Tonic"])
    }
}

/// The in-memory repositories must behave like the Core Data ones, since tests and previews rely on them.
struct InMemoryParityTests {
    @Test func restoringActiveBrewIsNotFound() async {
        let repository = InMemoryRecordRepository(brews: Brew.samples)

        await #expect(throws: RepositoryError.notFound) {
            try await repository.restore(brewID: Brew.samples[0].id)
        }
    }

    @Test func deviceDuplicateCheckTrims() async throws {
        let devices = InMemoryRecordRepository(devices: Device.samples)

        #expect(try await devices.contains(name: "  hario v60 02 ", type: .dripper))
    }

    @Test func profileChangesEmitOnSave() async throws {
        let profiles = InMemoryProfileRepository()
        var changes = await profiles.changes().makeAsyncIterator()

        try await profiles.saveProfile(UserProfile(name: "Олена"))

        #expect(await changes.next() != nil)
    }
}
