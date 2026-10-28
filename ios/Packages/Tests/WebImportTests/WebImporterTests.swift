import Foundation
import Testing
import Domain
@testable import WebImport

struct WebImporterTests {
    private let importedAt = Date(timeIntervalSince1970: 1_761_500_000)

    private func fixtureData() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "web-state", withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    private func importFixture() throws -> WebImport {
        try WebImporter.decode(try fixtureData(), importedAt: importedAt)
    }

    private func brew(_ legacyID: Int, in result: WebImport) throws -> Brew {
        try #require(result.brews.first { $0.legacyID == legacyID })
    }

    // MARK: - Counts & structure

    @Test func importsAllRecordKinds() throws {
        let result = try importFixture()

        #expect(result.beans.count == 2)
        #expect(result.devices.count == 3)
        #expect(result.filterPacks.count == 1)
        // 3 active brews + 1 log-only entry + 1 trashed. The brew without an id is skipped.
        #expect(result.brews.count == 5)
        #expect(result.brews.map(\.date) == result.brews.map(\.date).sorted(by: >))
    }

    @Test func importIsDeterministic() throws {
        let first = try importFixture()
        let second = try importFixture()

        #expect(first == second)
    }

    @Test func recordsAreIndependentOfImportTime() throws {
        let early = try WebImporter.decode(try fixtureData(), importedAt: Date(timeIntervalSince1970: 1))
        let late = try WebImporter.decode(try fixtureData(), importedAt: Date(timeIntervalSince1970: 2_000_000_000))

        #expect(early.beans == late.beans)
        #expect(early.devices == late.devices)
        #expect(early.filterPacks == late.filterPacks)
    }

    // MARK: - Brews

    @Test func mapsAlternativeBrew() throws {
        let v60 = try brew(20, in: try importFixture())

        #expect(v60.id == WebImporter.id(for: .brew, legacyID: 20))
        #expect(v60.date == Date(timeIntervalSince1970: 1_761_300_000))
        #expect(v60.method == .v60)
        #expect(v60.category == .filter)
        #expect(v60.bean == BeanReference(
            beanID: WebImporter.id(for: .bean, legacyID: 5),
            name: "Ethiopia Yirgacheffe",
            roaster: "Wonder&Full",
            roastProfile: .filter
        ))
        #expect(v60.dripper == GearReference(id: WebImporter.id(for: .device, legacyID: 1), name: "Hario V60 02"))
        #expect(v60.filter?.id == WebImporter.id(for: .filter, legacyID: 7))
        #expect(v60.isFilterRinsed == true)
        #expect(v60.grindSetting == 24)
        #expect(v60.doseGrams == 16)
        #expect(v60.waterTemperature == 93)
        #expect(v60.ratio == 16)
        #expect(v60.totalTime == 185)
        #expect(v60.aeropress == nil)
        #expect(v60.rating == 9.2)
        #expect(v60.flavors == ["Жасмин", "Бергамот"])
        #expect(v60.aromas == ["Чай"])
        #expect(v60.isLiked)
        #expect(v60.origin == .home)
        #expect(!v60.isManual)
        #expect(v60.beverageVolume == nil)
    }

    @Test func mapsStepsAndDropsUnknownOnes() throws {
        let steps = try brew(20, in: try importFixture()).steps

        #expect(steps == [
            BrewStep(kind: .pour(milliliters: 50), start: 0, duration: 10),
            BrewStep(kind: .pause, start: 10, duration: 35),
            BrewStep(kind: .action(.stir), start: 45, duration: 4),
            BrewStep(kind: .pour(milliliters: 206.5), start: 49, duration: 20),
        ])
        #expect(steps.totalPouredMilliliters == 256.5)
    }

    @Test func mapsEspressoDrink() throws {
        let cappuccino = try brew(21, in: try importFixture())

        #expect(cappuccino.method == .cappuccino)
        #expect(cappuccino.category == .espresso)
        #expect(cappuccino.espresso == EspressoShot(
            doseGrams: 18, targetYieldGrams: 36, actualYieldGrams: nil, shotTime: 28,
            targetTDS: nil, actualTDS: nil, pressureBar: 9
        ))
        #expect(cappuccino.totalTime == 28)
        #expect(cappuccino.ratio == 2)
        #expect(cappuccino.milk == MilkInfo(name: "Молоко 3.2%", temperature: 60, volumeMilliliters: 120, frother: "Стимер"))
        #expect(cappuccino.ice == nil)
        #expect(cappuccino.espressoMachine == GearReference(id: WebImporter.id(for: .device, legacyID: 99), name: "Gaggia Classic Pro"))
        #expect(cappuccino.accessoryIDs == [WebImporter.id(for: .device, legacyID: 3)])
        #expect(cappuccino.volumeMilliliters == 36)
    }

    @Test func mapsManualCafeVisit() throws {
        let flatWhite = try brew(22, in: try importFixture())

        #expect(flatWhite.isManual)
        #expect(flatWhite.origin == .cafe(place: "Blackwood Coffee"))
        #expect(flatWhite.beverageVolume == 180)
        #expect(flatWhite.totalTime == nil)
        #expect(flatWhite.dripper == nil)
        #expect(flatWhite.grinder == nil)
        #expect(flatWhite.grindSetting == nil)
        #expect(flatWhite.isFilterRinsed == nil)
    }

    @Test func turnsLogOnlyEntryIntoManualBrew() throws {
        let aeropress = try brew(15, in: try importFixture())

        #expect(aeropress.isManual)
        #expect(aeropress.method == .aeropress)
        #expect(aeropress.category == .immersion)
        #expect(aeropress.bean?.name == "Kenya AA")
        #expect(aeropress.bean?.beanID == nil)
        #expect(aeropress.grinder?.name == "Timemore C3")
        #expect(aeropress.doseGrams == 15)
        #expect(aeropress.ratio == 14)
        #expect(aeropress.waterTemperature == 85)
        #expect(aeropress.beverageVolume == 240)
        #expect(aeropress.rating == 8.5)
        #expect(aeropress.origin == .home)
    }

    @Test func importsTrashedBrewOnceAsDeleted() throws {
        let result = try importFixture()
        let trashed = result.brews.filter { $0.legacyID == 23 }

        #expect(trashed.count == 1)
        #expect(trashed.first?.deletedAt == Date(timeIntervalSince1970: 1_761_400_000))
        #expect(trashed.first?.isDeleted == true)
    }

    // MARK: - Inventory, profile, misc

    @Test func mapsBeansLeniently() throws {
        let beans = try importFixture().beans
        let yirgacheffe = try #require(beans.first { $0.legacyID == 5 })
        let brazil = try #require(beans.first { $0.legacyID == 6 })

        #expect(yirgacheffe.remainingGrams == 154)
        #expect(yirgacheffe.process == .washed)
        #expect(yirgacheffe.score == 87.5)
        #expect(yirgacheffe.roastProfile == .filter)
        #expect(yirgacheffe.updatedAt == Date(timeIntervalSince1970: 1_761_000_000))

        // "1000" as a string, empty score / process / roast type, no `_upd`.
        #expect(brazil.totalGrams == 1_000)
        #expect(brazil.remainingGrams == 420)
        #expect(brazil.score == nil)
        #expect(brazil.process == nil)
        #expect(brazil.roastProfile == nil)
        #expect(brazil.updatedAt == WebImporter.unknownUpdateDate)
    }

    @Test func mapsDevicesAndFilters() throws {
        let result = try importFixture()

        #expect(result.devices.map(\.type) == [.dripper, .grinder, .accessory])
        #expect(result.filterPacks.first?.remaining == 64)
        #expect(result.filterPacks.first?.total == 100)
    }

    @Test func mapsProfileAchievementsAndSuggestions() throws {
        let result = try importFixture()

        #expect(result.profile == UserProfile(
            name: "Олена", location: "Київ", title: "Бариста", experience: "3 роки",
            avatar: Avatar(emoji: "☕", colorHex: "#B87333"),
            updatedAt: importedAt
        ))
        #expect(result.achievements.map(\.achievementID) == ["brew_1", "pack_1"])
        #expect(result.suggestions.roasters == ["Wonder&Full", "Penyora"])
        #expect(result.suggestions.mixers == ["Тонік"])
    }

    // MARK: - Input formats & errors

    @Test func acceptsBackendRowWrapper() throws {
        let state = try JSONSerialization.jsonObject(with: try fixtureData())
        let wrapped = try JSONSerialization.data(withJSONObject: ["telegram_id": "1", "data": state])

        let result = try WebImporter.decode(wrapped, importedAt: importedAt)

        #expect(result == (try importFixture()))
    }

    @Test func rejectsInvalidJSON() {
        #expect(throws: WebImportError.invalidJSON) {
            try WebImporter.decode(Data("not json".utf8))
        }
    }

    @Test func rejectsUnrelatedJSON() {
        #expect(throws: WebImportError.unrecognizedFormat) {
            try WebImporter.decode(Data(#"{"hello":"world"}"#.utf8))
        }
    }

    @Test func emptyStateImportsNothing() throws {
        let result = try WebImporter.decode(Data(#"{"brews":[],"beans":[],"log":[]}"#.utf8))

        #expect(result.isEmpty)
    }

    // MARK: - Helpers

    @Test func stableIDsAreVersion5AndKindSpecific() {
        let brewID = WebImporter.id(for: .brew, legacyID: 1)

        #expect(brewID == WebImporter.id(for: .brew, legacyID: 1))
        #expect(brewID != WebImporter.id(for: .bean, legacyID: 1))
        #expect(brewID != WebImporter.id(for: .brew, legacyID: 2))
        #expect(brewID.uuidString.dropFirst(14).first == "5")
    }

    @Test(arguments: [
        ("3:05", 185.0), ("0:28", 28), ("28с", 28), ("28s", 28), ("45", 45),
    ])
    func parsesDurations(_ input: String, expected: Double) {
        #expect(WebImporter.parseDuration(input) == expected)
    }

    @Test(arguments: ["—", "", "   "])
    func emptyDurationsAreNil(_ input: String) {
        #expect(WebImporter.parseDuration(input) == nil)
    }

    @Test(arguments: [
        ("16.0", 16.0), ("93°C", 93), ("28с", 28), ("1,5", 1.5), ("-2 g", -2),
    ])
    func parsesLenientNumbers(_ input: String, expected: Double) {
        #expect(LenientNumber.parse(input) == expected)
    }
}
