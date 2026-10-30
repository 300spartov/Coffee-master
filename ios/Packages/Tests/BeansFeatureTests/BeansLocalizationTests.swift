import Testing
@testable import BeansFeature

struct BeansLocalizationTests {
    @Test func resolvesInBothLanguages() {
        #expect(tr("No beans yet", language: .ukrainian) == "Немає зерна")
        #expect(tr("No beans yet", language: .english) == "No beans yet")
        #expect(tr("Delete Bean", language: .ukrainian) == "Видалити пачку")
        #expect(tr("Delete Bean", language: .english) == "Delete Bean")
    }
}
