import Foundation
import Testing
import Domain
import WebImport
@testable import DataLayer

struct WebImportServiceTests {
    private let persistence: PersistenceController
    private let service: WebImportService

    init() throws {
        persistence = try PersistenceController(location: .inMemory)
        service = WebImportService(persistence: persistence)
    }

    private func sampleImport(profileName: String = "Олена") -> WebImport {
        WebImport(
            profile: UserProfile(name: profileName),
            beans: Bean.samples,
            devices: [Device(id: .fixture(201), updatedAt: Date(timeIntervalSince1970: 10), name: "Hario V60 02", type: .dripper)],
            filterPacks: [FilterPack(id: .fixture(301), updatedAt: Date(timeIntervalSince1970: 10), name: "Cafec", total: 100, remaining: 40)],
            brews: Brew.samples,
            achievements: [EarnedAchievement(achievementID: "brew_1", earnedAt: Date(timeIntervalSince1970: 100))],
            suggestions: Suggestions(roasters: ["Penyora"], milks: ["Oat"])
        )
    }

    @Test func savesEverything() async throws {
        let summary = try await service.save(sampleImport())

        #expect(summary.brews == UpsertResult(inserted: 3))
        #expect(summary.beans == UpsertResult(inserted: 2))
        #expect(summary.devices == UpsertResult(inserted: 1))
        #expect(summary.filterPacks == UpsertResult(inserted: 1))
        #expect(summary.achievementsAdded == 1)
        #expect(summary.profileImported)
        #expect(summary.changedCount == 8)

        let documents = DocumentStore(persistence: persistence)
        #expect(try await RecordStore<Brew>(persistence: persistence).count() == 3)
        #expect(try await documents.load(UserProfile.self, key: .profile)?.name == "Олена")
        #expect(try await documents.load(Suggestions.self, key: .suggestions)?.milks == ["Oat"])
    }

    @Test func importingTwiceChangesNothingNew() async throws {
        try await service.save(sampleImport())
        let second = try await service.save(sampleImport())

        #expect(second.brews == UpsertResult(unchanged: 3))
        #expect(second.beans == UpsertResult(unchanged: 2))
        #expect(second.changedCount == 0)
        #expect(second.achievementsAdded == 0)
        #expect(!second.profileImported)
        #expect(try await RecordStore<Brew>(persistence: persistence).count() == 3)
    }

    @Test func localEditsSurviveReimport() async throws {
        try await service.save(sampleImport())
        let repository = CoreDataBrewRepository(persistence: persistence)
        var edited = try await repository.fetch(id: Brew.samples[0].id)
        edited.notes = "edited after import"
        try await repository.save(edited)

        let second = try await service.save(sampleImport())

        #expect(second.brews.skipped >= 1)
        #expect(try await repository.fetch(id: Brew.samples[0].id).notes == "edited after import")
    }

    @Test func existingProfileIsNotOverwritten() async throws {
        try await DocumentStore(persistence: persistence).save(UserProfile(name: "Local Name"), key: .profile)

        let summary = try await service.save(sampleImport(profileName: "Imported"))

        #expect(!summary.profileImported)
        #expect(try await DocumentStore(persistence: persistence).load(UserProfile.self, key: .profile)?.name == "Local Name")
    }

    @Test func achievementsMergeKeepingEarliestDate() {
        let local = [EarnedAchievement(achievementID: "a", earnedAt: Date(timeIntervalSince1970: 200))]
        let imported = [
            EarnedAchievement(achievementID: "a", earnedAt: Date(timeIntervalSince1970: 100)),
            EarnedAchievement(achievementID: "b", earnedAt: Date(timeIntervalSince1970: 300)),
        ]

        let merged = EarnedAchievement.merge(local, imported)

        #expect(merged == [
            EarnedAchievement(achievementID: "a", earnedAt: Date(timeIntervalSince1970: 100)),
            EarnedAchievement(achievementID: "b", earnedAt: Date(timeIntervalSince1970: 300)),
        ])
    }

    @Test func importsJSONFile() async throws {
        let json = #"""
        {"brews":[{"id":1,"ts":1761300000000,"method":"V60","dose":"15","ratio":16,"rating":9}],
         "beans":[{"id":2,"name":"Kenya","total":250,"current":200}],
         "log":[]}
        """#
        let summary = try await service.importJSON(Data(json.utf8))

        #expect(summary.brews.inserted == 1)
        #expect(summary.beans.inserted == 1)
    }

    @Test func rejectsNonExportFile() async {
        await #expect(throws: WebImportError.unrecognizedFormat) {
            try await service.importJSON(Data(#"{"foo":1}"#.utf8))
        }
    }
}
