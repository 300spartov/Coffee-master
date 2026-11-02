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
        pickers.element(boundBy: 0).tap()
        XCTAssertFalse(app.buttons["journal.compareBar"].exists, "Two brews are needed")
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
        attachScreenshot(named: "compare-timeline")
        app.segmentedControls["compare.chart"].buttons["Rings"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["compare.rings"].waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "compare.entry").firstMatch.tap()
        attachScreenshot(named: "compare-rings")
        app.segmentedControls["compare.chart"].buttons["Curve"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["compare.curve"].waitForExistence(timeout: 5))
        attachScreenshot(named: "compare-curve")

        app.navigationBars["Compare"].buttons.firstMatch.tap()
        app.buttons["journal.compareReset"].tap()
        XCTAssertTrue(app.buttons["journal.compareBar"].waitForNonExistence(timeout: 5))
    }

    func testCancelClosesTheLog() {
        let app = XCUIApplication.launched()
        app.navigationBars["Journal"].buttons["journal.log"].tap()
        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForExistence(timeout: 5))

        app.navigationBars["Log a Brew"].buttons["Cancel"].tap()

        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForNonExistence(timeout: 5))
    }
}
