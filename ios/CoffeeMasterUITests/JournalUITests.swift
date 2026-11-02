import XCTest

/// The Journal (ROADMAP 3.3): logging a brew after the fact. Logs a café drink (it takes nothing from
/// stock) and deletes it again.
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
        ours.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(ours.waitForNonExistence(timeout: 5))
    }

    func testCancelClosesTheLog() {
        let app = XCUIApplication.launched()
        app.navigationBars["Journal"].buttons["journal.log"].tap()
        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForExistence(timeout: 5))

        app.navigationBars["Log a Brew"].buttons["Cancel"].tap()

        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForNonExistence(timeout: 5))
    }
}
