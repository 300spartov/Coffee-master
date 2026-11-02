import Testing
import Domain
@testable import BrewKit

struct BrewTextTests {
    @Test func labelsResolveInBothLanguages() {
        #expect(ratioText(16) == "1:16.0")
        #expect(tr("Bloom", language: .ukrainian) == "Блум")
        #expect(tr("Stir", language: .english) == "Stir")
        #expect(BrewStep(kind: .action(.swirl), start: 0, duration: 5).title == BrewAction.swirl.title)
        #expect(BrewAction(rawValue: "Tap").title == "Tap")
    }
}
