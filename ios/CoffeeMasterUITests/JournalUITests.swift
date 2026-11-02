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
        app.buttons["settings.trash"].tap()
        XCTAssertTrue(app.navigationBars["Deleted Brews"].waitForExistence(timeout: 5))
        let trashed = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == 'trash.brew' AND label CONTAINS %@", place)).firstMatch
        XCTAssertTrue(trashed.waitForExistence(timeout: 5))
        XCTAssertTrue(trashed.label.contains("30 days left"), trashed.label)
        attachScreenshot(named: "trash")
        trashed.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(trashed.waitForNonExistence(timeout: 5))
    }

    func testCancelClosesTheLog() {
        let app = XCUIApplication.launched()
        app.navigationBars["Journal"].buttons["journal.log"].tap()
        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForExistence(timeout: 5))

        app.navigationBars["Log a Brew"].buttons["Cancel"].tap()

        XCTAssertTrue(app.navigationBars["Log a Brew"].waitForNonExistence(timeout: 5))
    }
}
