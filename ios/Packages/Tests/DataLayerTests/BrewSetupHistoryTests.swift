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
