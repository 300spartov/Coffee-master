import Foundation
import Testing
import Domain
@testable import DataLayer

struct UserDefaultsBrewSetupHistoryTests {
    private let defaults: UserDefaults
    private let suite = "BrewSetupHistoryTests.\(UUID().uuidString)"

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suite))
    }

    @Test func remembersAcrossInstances() async {
        var setup = BrewSetup(method: .aeropress)
        setup.bean = BeanReference(beanID: .fixture(1), name: "Kenya")
        setup.aeropress = AeroPressOptions(isInverted: true, filterCount: 2)

        await UserDefaultsBrewSetupHistory(defaults: defaults).remember(setup)

        #expect(await UserDefaultsBrewSetupHistory(defaults: defaults).recentSetups() == [setup])
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func unreadableValueMeansNoHistory() async {
        defaults.set(Data("nope".utf8), forKey: UserDefaultsBrewSetupHistory.key)

        #expect(await UserDefaultsBrewSetupHistory(defaults: defaults).recentSetups().isEmpty)
        defaults.removePersistentDomain(forName: suite)
    }
}

struct UserDefaultsEspressoHistoryTests {
    @Test func espressoSetupsAreKeptSeparately() async throws {
        let suite = "EspressoHistoryTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var shot = EspressoSetup(method: .latte)
        shot.doseGrams = 19
        let history = UserDefaultsBrewSetupHistory(defaults: defaults)

        await history.remember(shot)
        await history.remember(BrewSetup(method: .v60))

        #expect(await UserDefaultsBrewSetupHistory(defaults: defaults).recentEspressoSetups() == [shot])
        #expect(await history.recentSetups().map(\.method) == [.v60])
    }
}

struct UserDefaultsDraftStoreTests {
    @Test func savesLoadsAndRemoves() throws {
        let suite = "DraftStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsDraftStore(defaults: defaults)

        store.save(BrewTasting(rating: 9, notes: "Juicy"), key: "draft")
        #expect(UserDefaultsDraftStore(defaults: defaults).load(BrewTasting.self, key: "draft")?.rating == 9)

        store.remove("draft")
        #expect(store.load(BrewTasting.self, key: "draft") == nil)
        defaults.set(Data("nope".utf8), forKey: "draft")
        #expect(store.load(BrewTasting.self, key: "draft") == nil)
    }
}
