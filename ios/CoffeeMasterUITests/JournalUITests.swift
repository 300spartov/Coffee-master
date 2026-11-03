import XCTest

/// The Journal: logging a brew after the fact (ROADMAP 3.3), then delete, Undo and the trash (3.4).
/// Works only with the café drink it logs (it takes nothing from stock), which ends up deleted for good;
/// it never empties the trash.
@MainActor
final class JournalUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testLogACafeDrink() {
        let app = XCUIApplication.launched()
        let place = "UI Café \(Int.random(in: 1000...9999))"
        app.navigationBars["Journal"].buttons["journal.log"].tap()
        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForExistence(timeout: 5))

        app.segmentedControls["brewForm.source"].buttons["Café"].tap()
        let placeField = app.textFields["brewForm.place"]
        XCTAssertTrue(placeField.waitForExistence(timeout: 5))
        placeField.tap()
        placeField.typeText(place)
        // Every keyboard has Done above it.
        attachScreenshot(named: "keyboard-done")
        app.buttons["keyboard.done"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.textFields["brewForm.dose"].exists, "A café drink has no recipe")
        attachScreenshot(named: "log-brew")
        scrollTo(app.buttons["brewForm.save"], inForm: "brewForm", of: app).tap()

        // Logged now, so it's the newest card; delete it only if it's ours.
        XCTAssertTrue(app.staticTexts["Brew added"].waitForExistence(timeout: 5))
        let card = app.collectionViews.firstMatch.cells.containing(.button, identifier: "journal.brew").firstMatch
        let ours = card.buttons.matching(NSPredicate(format: "identifier == 'journal.brew' AND label CONTAINS %@", place)).firstMatch
        XCTAssertTrue(ours.waitForExistence(timeout: 5), "The logged drink should be the newest card")
        guard ours.exists else { return }
        XCTAssertTrue(card.staticTexts["240, ml, Volume"].exists)
        attachScreenshot(named: "logged-card")

        // Delete → Undo brings it back.
        ours.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(ours.waitForNonExistence(timeout: 5))
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        undo.tap()
        XCTAssertTrue(ours.waitForExistence(timeout: 5), "Undo should restore the drink")

        // Delete again → it's in Profile → Deleted Brews; delete it for good there.
        ours.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(ours.waitForNonExistence(timeout: 5))
        app.tabBars.buttons["Profile"].tap()
        app.buttons["profile.trash"].tap()
        XCTAssertTrue(app.navigationBars["Deleted Brews"].waitForExistence(timeout: 5))
        let trashed = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == 'trash.brew' AND label CONTAINS %@", place)).firstMatch
        XCTAssertTrue(trashed.waitForExistence(timeout: 5))
        XCTAssertTrue(trashed.label.contains("30 days left"), trashed.label)
        attachScreenshot(named: "trash")
        trashed.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(trashed.waitForNonExistence(timeout: 5))
    }

    /// ROADMAP 3.5: pick two brews with ⚖, compare them in the three charts. Read-only (picking doesn't
    /// change a brew), so it uses the brews already in the journal.
    func testCompareTwoBrews() throws {
        let app = XCUIApplication.launched()
        let pickers = app.buttons.matching(identifier: "journal.compare")
        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 5))
        try XCTSkipUnless(pickers.firstMatch.waitForExistence(timeout: 5), "Needs brews in the journal")
        // The first by swiping it right, the second with its ⚖ button.
        app.collectionViews.firstMatch.cells.containing(.button, identifier: "journal.brew").firstMatch.buttons["journal.brew"].swipeRight()
        XCTAssertTrue(app.buttons["journal.swipeLike"].exists, "Like sits next to Compare")
        app.buttons["journal.swipeCompare"].tap()
        // One brew: the bar shows, but Compare waits for a second.
        XCTAssertTrue(app.buttons["journal.compareBar"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["journal.compareBar"].isEnabled, "Two brews are needed")
        try XCTSkipUnless(pickers.count >= 2, "Needs two brews in the journal")
        pickers.element(boundBy: 1).tap()
        let bar = app.buttons["journal.compareBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        attachScreenshot(named: "compare-bar")
        // The bar belongs to the Journal (on iOS 26 it rides on the tab bar): gone on other tabs.
        app.tabBars.buttons["Beans"].tap()
        XCTAssertTrue(bar.waitForNonExistence(timeout: 5))
        app.tabBars.buttons["Journal"].tap()
        XCTAssertTrue(bar.waitForExistence(timeout: 5))

        bar.tap()
        XCTAssertTrue(app.navigationBars["Compare"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "compare.timeline").count, 2)
        XCTAssertTrue(app.descendants(matching: .any)["compare.parameters"].exists)
        // Tapping a brew selects it: its steps open.
        let firstTimeline = app.descendants(matching: .any).matching(identifier: "compare.timeline").firstMatch
        firstTimeline.tap()
        XCTAssertTrue(firstTimeline.staticTexts.matching(NSPredicate(format: "label CONTAINS '–'")).firstMatch.waitForExistence(timeout: 5), "The selected brew shows its steps")
        attachScreenshot(named: "compare-timeline")
        app.segmentedControls["compare.chart"].buttons["Rings"].tap()
        let rings = app.descendants(matching: .any)["compare.rings"]
        XCTAssertTrue(rings.waitForExistence(timeout: 5))
        // The outer ring (the first brew), near its top edge.
        rings.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).tap()
        attachScreenshot(named: "compare-rings")
        app.segmentedControls["compare.chart"].buttons["Curve"].tap()
        let curve = app.descendants(matching: .any)["compare.curve"]
        XCTAssertTrue(curve.waitForExistence(timeout: 5))
        curve.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        attachScreenshot(named: "compare-curve")

        app.navigationBars["Compare"].buttons.firstMatch.tap()
        app.buttons["journal.compareReset"].tap()
        XCTAssertTrue(app.buttons["journal.compareBar"].waitForNonExistence(timeout: 5))
    }

    /// ROADMAP 3.6: the filter sheet, clearing it, then search. Read-only (filters change no brew).
    func testSearchAndFilters() throws {
        let app = XCUIApplication.launched()
        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 5))
        let cards = app.buttons.matching(identifier: "journal.brew")
        try XCTSkipUnless(cards.firstMatch.waitForExistence(timeout: 5), "Needs brews in the journal")
        let noMatch = app.staticTexts["No brews match"]

        // The filter sheet: the first method and Liked apply at once; Done shows "Filtered by" over the feed.
        app.buttons["journal.filters"].tap()
        XCTAssertTrue(app.navigationBars["Filters"].waitForExistence(timeout: 5))
        // Drag the lowest-rating thumb right, about halfway.
        let lowest = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == 'filters.rating' AND label == 'Lowest rating'")).firstMatch
        XCTAssertTrue(lowest.exists)
        let start = lowest.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.2, thenDragTo: start.withOffset(CGVector(dx: 150, dy: 0)))
        app.buttons.matching(identifier: "filters.method").firstMatch.tap()
        app.switches["filters.liked"].switches.firstMatch.tap()
        attachScreenshot(named: "journal-filters")
        app.buttons["filters.done"].tap()
        let summary = app.buttons["journal.filterSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("Liked") && summary.label.contains("Rating"), summary.label)
        XCTAssertTrue(cards.firstMatch.exists || noMatch.exists)
        attachScreenshot(named: "journal-filtered")

        // Tapping the summary reopens the sheet; ✕ clears everything.
        summary.tap()
        XCTAssertTrue(app.navigationBars["Filters"].waitForExistence(timeout: 5))
        app.buttons["filters.done"].tap()
        app.buttons["journal.filterClear"].tap()
        XCTAssertTrue(summary.waitForNonExistence(timeout: 5))
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 5))

        // Last (an active search hides the bar buttons): search for something no brew has. The "no match"
        // state has no Clear Filters (nothing to clear); clearing the text brings the brews back.
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("zzqx\(Int.random(in: 1000...9999))")
        XCTAssertTrue(noMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Clear Filters"].exists)
        attachScreenshot(named: "journal-no-match")
        // The Search key closes the keyboard and keeps the search (no Done bar on the search field).
        XCTAssertFalse(app.buttons["keyboard.done"].exists)
        app.keyboards.buttons["search"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertTrue(noMatch.exists)
        search.buttons["Clear text"].tap()
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 5))
    }

    func testCancelClosesTheLog() {
        let app = XCUIApplication.launched()
        app.navigationBars["Journal"].buttons["journal.log"].tap()
        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForExistence(timeout: 5))

        app.navigationBars["Log a Brew"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForNonExistence(timeout: 5))

        // The brew wizard's "Log a Brew" closes the wizard and opens the same sheet on the Journal.
        app.brewButton.tap()
        app.buttons["brew.log"].tap()
        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["New Brew"].waitForNonExistence(timeout: 5))
        app.navigationBars["Log a Brew"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 5))
        attachScreenshot(named: "journal-bar")
    }
}
