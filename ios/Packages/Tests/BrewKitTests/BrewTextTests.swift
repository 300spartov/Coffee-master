import Testing
import Domain
@testable import BrewKit

struct BrewTextTests {
    @Test func numbersAndTimes() {
        #expect(clockText(125.9) == "2:05")
        #expect(decimal(16) == "16")
        #expect(decimal(15.55) == "15.6")
        #expect(ratioText(16) == "1:16.0")
    }

    @Test func labelsResolveInBothLanguages() {
        #expect(tr("Bloom", language: .ukrainian) == "Блум")
        #expect(tr("Stir", language: .english) == "Stir")
        #expect(BrewStep(kind: .action(.swirl), start: 0, duration: 5).title == BrewAction.swirl.title)
        #expect(BrewAction(rawValue: "Tap").title == "Tap")
    }
}
