import Testing
import Domain
@testable import JournalFeature

struct BrewFilterTests {
    private let ethiopia = Brew(
        method: .v60,
        bean: BeanReference(name: "Ethiopia Guji", roaster: "Penyora"),
        dripper: GearReference(name: "Hario V60"),
        doseGrams: 16, ratio: 16, rating: 9, flavors: ["Манго"], notes: "Bright, juicy", isLiked: true
    )
    private let cafe = Brew(method: .latte, doseGrams: 18, ratio: 2, rating: 6.5, origin: .cafe(place: "Kávéház"))
    private let espresso = Brew(method: .espresso, bean: BeanReference(name: "Brazil Cerrado"), doseGrams: 18, ratio: 2, rating: 4)

    private func shown(_ filter: BrewFilter) -> [Brew] {
        [ethiopia, cafe, espresso].filter(filter.matches)
    }

    @Test func theDefaultShowsEverything() {
        let filter = BrewFilter()
        #expect(filter.isEmpty && !filter.hasFilters)
        #expect(shown(filter) == [ethiopia, cafe, espresso])
    }

    @Test func textMatchesNamesNotesAndTagsIgnoringCaseAndDiacritics() {
        #expect(shown(BrewFilter(text: "  penyora ")) == [ethiopia])   // roaster, trimmed
        #expect(shown(BrewFilter(text: "hario")) == [ethiopia])        // brewer
        #expect(shown(BrewFilter(text: "JUICY")) == [ethiopia])        // notes
        #expect(shown(BrewFilter(text: "манго")) == [ethiopia])        // a flavor tag
        #expect(shown(BrewFilter(text: "kavehaz")) == [cafe])          // café, without accents
        #expect(shown(BrewFilter(text: "espresso")) == [espresso])     // method
        #expect(shown(BrewFilter(text: "nothing")).isEmpty)
    }

    @Test func filtersCombine() {
        #expect(shown(BrewFilter(methods: [.latte, .espresso])) == [cafe, espresso])
        #expect(shown(BrewFilter(rating: 6.5...10)) == [ethiopia, cafe])   // the ends count
        #expect(shown(BrewFilter(isLikedOnly: true)) == [ethiopia])
        #expect(shown(BrewFilter(methods: [.latte, .espresso], rating: 5...10)) == [cafe])
        #expect(shown(BrewFilter(text: "brazil", methods: [.latte])).isEmpty)
    }

    @Test func summaryListsWhatIsOn() throws {
        #expect(BrewFilter(text: "guji").summary.isEmpty)
        let filter = BrewFilter(methods: [.v60, .chemex], rating: 7...10, isLikedOnly: true)
        let range = try #require(filter.ratingRangeText)
        #expect(filter.summary == [tr("Liked"), tr("Rating \(range)"), "Chemex", "V60"])
        #expect(BrewFilter().ratingRangeText == nil)
    }

    @Test func clearKeepsTheSearchText() {
        var filter = BrewFilter(text: "guji", methods: [.v60], rating: 8...10, isLikedOnly: true)
        #expect(filter.hasFilters)
        filter.clear()
        #expect(filter == BrewFilter(text: "guji"))
        #expect(!filter.hasFilters && !filter.isEmpty)
    }
}
