import Testing
@testable import BrewsFeature

struct BrewsLocalizationTests {
    @Test func resolvesInBothLanguages() {
        #expect(tr("No brews yet", language: .ukrainian) == "Ще немає рецептів")
        #expect(tr("No brews yet", language: .english) == "No brews yet")
    }
}
