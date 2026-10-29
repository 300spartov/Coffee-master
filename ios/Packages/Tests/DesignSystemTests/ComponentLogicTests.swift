import CoreGraphics
import Testing
@testable import DesignSystem

struct StockLevelTests {
    @Test(arguments: [
        (0.0, StockLevel.empty), (-1, .empty), (0.05, .low), (0.2, .low), (0.21, .normal), (1, .normal),
    ])
    func levelFromFraction(_ fraction: Double, expected: StockLevel) {
        #expect(StockLevel(fraction: fraction) == expected)
    }

    @Test func customThreshold() {
        #expect(StockLevel(fraction: 0.3, lowThreshold: 0.5) == .low)
    }
}

struct FlowLayoutTests {
    private let chip = CGSize(width: 40, height: 20)

    @Test func wrapsWhenRowIsFull() {
        let result = FlowLayout.arrange([chip, chip, chip], maxWidth: 100, spacing: 10)

        // 40 + 10 + 40 = 90 fits; the third (would end at 140) wraps.
        #expect(result.origins == [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 0), CGPoint(x: 0, y: 30)])
        #expect(result.size == CGSize(width: 90, height: 50))
    }

    @Test func oversizedItemGetsItsOwnRow() {
        let wide = CGSize(width: 300, height: 20)
        let result = FlowLayout.arrange([chip, wide, chip], maxWidth: 100, spacing: 10)

        #expect(result.origins.map(\.y) == [0, 30, 60])
    }

    @Test func emptyHasZeroSize() {
        #expect(FlowLayout.arrange([], maxWidth: 100, spacing: 10).size == .zero)
    }

    @Test func unlimitedWidthIsOneRow() {
        let result = FlowLayout.arrange([chip, chip, chip], maxWidth: .infinity, spacing: 8)

        #expect(result.origins.map(\.y) == [0, 0, 0])
        #expect(result.size.width == 136)
    }
}

struct NumberFieldTests {
    @Test(arguments: [(-5.0, 1.0), (16, 16), (99, 60)])
    func clampsToRange(_ input: Double, expected: Double) {
        #expect(NumberField.clamp(input, to: 1...60) == expected)
    }
}

struct DesignSystemLocalizationTests {
    @Test func resolvesInBothLanguages() {
        #expect(tr("Retry", language: .ukrainian) == "Спробувати ще")
        #expect(tr("Retry", language: .english) == "Retry")
        #expect(tr("Rating \("8.5") of 10", language: .ukrainian) == "Оцінка 8.5 з 10")
    }
}

struct AutocompleteTests {
    private let roasters = ["Penyora", "Wonder&Full", "Mad Heads", "penyora", "Pérez Coffee", "Svit Kavy"]

    @Test func prefixMatchesFirstThenContains() {
        #expect(Autocomplete.matches(for: "pe", in: roasters) == ["Penyora", "Pérez Coffee"])
        #expect(Autocomplete.matches(for: "ad", in: roasters) == ["Mad Heads"])
    }

    @Test func caseAndDiacriticInsensitiveAndDeduplicated() {
        #expect(Autocomplete.matches(for: "PEREZ", in: roasters) == ["Pérez Coffee"])
        #expect(Autocomplete.matches(for: "", in: roasters, limit: 3) == ["Penyora", "Wonder&Full", "Mad Heads"])
    }

    @Test func exactValueIsNotSuggested() {
        #expect(Autocomplete.matches(for: "penyora", in: roasters).isEmpty)
    }

    @Test func ignoresBlanksAndRespectsLimit() {
        #expect(Autocomplete.matches(for: "", in: ["", "  ", "A", "B"], limit: 1) == ["A"])
    }
}
