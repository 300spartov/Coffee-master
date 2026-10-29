import Testing
@testable import BeansFeature

struct BeansLocalizationTests {
    @Test func resolvesInBothLanguages() {
        #expect(tr("No beans yet", language: .ukrainian) == "Немає зерна")
        #expect(tr("No beans yet", language: .english) == "No beans yet")
        #expect(tr("Running low", language: .ukrainian) == "Залишилось мало")
        #expect(tr("Running low", language: .english) == "Running low")
    }
}
