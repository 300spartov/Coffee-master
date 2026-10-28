import Foundation
import Testing
@testable import Domain

struct BrewMethodTests {
    @Test(arguments: [
        (BrewMethod.v60, BrewCategory.filter),
        (.chemex, .filter),
        (.batchBrewing, .filter),
        (.aeropress, .immersion),
        (.frenchPress, .immersion),
        (.coldBrew, .immersion),
        ("Moka", .immersion),
        (.espresso, .espresso),
        (.cappuccino, .espresso),
        (.flatWhite, .espresso),
        ("Еспресо", .espresso),
        ("Ice Latte", .espresso),
        ("Cortado", .espresso),
        ("Something new", .filter),
    ])
    func categorizesMethods(_ method: BrewMethod, expected: BrewCategory) {
        #expect(method.category == expected)
    }

    @Test func encodesAsPlainString() throws {
        let data = try JSONEncoder().encode(BrewMethod.frenchPress)

        #expect(String(decoding: data, as: UTF8.self) == #""French Press""#)
        #expect(try JSONDecoder().decode(BrewMethod.self, from: data) == .frenchPress)
    }

    @Test func trimsWhitespace() {
        #expect(BrewMethod(rawValue: "  V60 ") == .v60)
    }
}

struct BrewTests {
    @Test(arguments: [(-3.0, 0.0), (11, 10), (8.46, 8.5), (7.04, 7.0)])
    func clampsAndRoundsRating(_ input: Double, expected: Double) {
        #expect(Brew(method: .v60, doseGrams: 15, ratio: 16, rating: input).rating == expected)
    }

    @Test func volumePrefersExplicitThenEspressoThenPoursThenRecipe() {
        let recipeOnly = Brew(method: .v60, doseGrams: 15, ratio: 16, rating: 8)
        let poured = Brew(
            method: .v60, doseGrams: 15, ratio: 16,
            steps: [BrewStep(kind: .pour(milliliters: 120), start: 0, duration: 10),
                    BrewStep(kind: .pause, start: 10, duration: 20),
                    BrewStep(kind: .pour(milliliters: 110), start: 30, duration: 10)],
            rating: 8
        )
        let espresso = Brew(
            method: .espresso, doseGrams: 18, ratio: 2,
            espresso: EspressoShot(doseGrams: 18, targetYieldGrams: 36, actualYieldGrams: 40, shotTime: 30),
            rating: 8
        )
        let manual = Brew(method: .latte, doseGrams: 18, ratio: 2, beverageVolume: 300, rating: 8, isManual: true)

        #expect(recipeOnly.volumeMilliliters == 240)
        #expect(poured.volumeMilliliters == 230)
        #expect(poured.steps.pourCount == 2)
        #expect(espresso.volumeMilliliters == 40)
        #expect(manual.volumeMilliliters == 300)
    }

    @Test func espressoShotMakesCategoryEspresso() {
        let brew = Brew(
            method: "House special", doseGrams: 18, ratio: 2,
            espresso: EspressoShot(doseGrams: 18, targetYieldGrams: 36, shotTime: 27),
            rating: 8
        )

        #expect(brew.category == .espresso)
    }

    @Test func cafeOrigin() {
        #expect(Brew(method: .latte, doseGrams: 18, ratio: 2, rating: 8, origin: .cafe(place: "")).isCafeVisit)
        #expect(!Brew(method: .latte, doseGrams: 18, ratio: 2, rating: 8).isCafeVisit)
    }

    @Test func codableRoundTrip() throws {
        for brew in Brew.samples {
            let data = try JSONEncoder().encode(brew)
            #expect(try JSONDecoder().decode(Brew.self, from: data) == brew)
        }
    }

    @Test func softDeleteAndRestore() {
        var brew = Brew.samples[0]
        let deletedAt = Date(timeIntervalSince1970: 100)
        let restoredAt = Date(timeIntervalSince1970: 200)

        brew.markDeleted(at: deletedAt)
        #expect(brew.isDeleted)
        #expect(brew.updatedAt == deletedAt)

        brew.restore(at: restoredAt)
        #expect(!brew.isDeleted)
        #expect(brew.updatedAt == restoredAt)
    }
}

struct BeanTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    @Test func consumeNeverGoesNegativeAndTouches() {
        var bean = Bean(name: "Kenya", totalGrams: 250, remainingGrams: 20, updatedAt: .distantPast)

        bean.consume(grams: 15, at: now)
        #expect(bean.remainingGrams == 5)
        #expect(bean.updatedAt == now)

        bean.consume(grams: 15, at: now)
        #expect(bean.remainingGrams == 0)
        #expect(bean.isEmpty)
    }

    @Test func restockNeverExceedsBag() {
        var bean = Bean(name: "Kenya", totalGrams: 250, remainingGrams: 240)

        bean.restock(grams: 30, at: now)

        #expect(bean.remainingGrams == 250)
    }

    @Test func resizeKeepsUsedAmount() {
        var bean = Bean(name: "Kenya", totalGrams: 250, remainingGrams: 200)

        bean.resize(totalGrams: 1_000, at: now)
        #expect(bean.remainingGrams == 950)

        bean.resize(totalGrams: 30, at: now)
        #expect(bean.remainingGrams == 0)
    }

    @Test func initClampsRemaining() {
        #expect(Bean(name: "A", totalGrams: 250, remainingGrams: 400).remainingGrams == 250)
        #expect(Bean(name: "A", totalGrams: 250, remainingGrams: -5).remainingGrams == 0)
        #expect(Bean(name: "A", totalGrams: 250).remainingFraction == 1)
    }
}

private extension Bean {
    init(name: String, totalGrams: Double, remainingGrams: Double, updatedAt: Date) {
        self.init(updatedAt: updatedAt, name: name, totalGrams: totalGrams, remainingGrams: remainingGrams)
    }
}

struct FilterPackTests {
    @Test func useAndPutBackStayInBounds() {
        var pack = FilterPack(name: "Cafec", total: 100, remaining: 11)

        #expect(!pack.isLow)
        pack.use()
        #expect(pack.remaining == 10)
        #expect(pack.isLow)
        pack.use(count: 50)
        #expect(pack.remaining == 0)
        #expect(pack.isEmpty)
        pack.putBack(count: 500)
        #expect(pack.remaining == 100)
    }
}

struct SuggestionsTests {
    @Test func addsUniqueTrimmedValues() {
        var list = Suggestions.adding("Penyora", to: [])
        list = Suggestions.adding("  penyora ", to: list)
        list = Suggestions.adding("   ", to: list)
        list = Suggestions.adding(" Wonder&Full ", to: list)

        #expect(list == ["Penyora", "Wonder&Full"])
    }
}

struct UserProfileTests {
    @Test func initials() {
        #expect(UserProfile(name: "олена").initials == "О")
        #expect(UserProfile(name: "  ").initials == "?")
    }
}
