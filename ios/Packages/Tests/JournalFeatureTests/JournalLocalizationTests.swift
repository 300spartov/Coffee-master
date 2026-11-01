import Testing
@testable import JournalFeature

struct JournalLocalizationTests {
    @Test func resolvesInBothLanguages() {
        #expect(tr("No brews yet", language: .ukrainian) == "Ще немає рецептів")
        #expect(tr("No brews yet", language: .english) == "No brews yet")
    }
}
