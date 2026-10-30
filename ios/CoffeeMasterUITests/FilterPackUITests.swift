import XCTest

/// Filter packs end to end: Devices → Filters → add a pack → −/+ → edit what's left → remove.
/// Uses a unique name and removes the pack it adds.
@MainActor
final class FilterPackUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testAddUseEditAndRemoveFilterPack() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://devices")
        let name = "UI Filters \(Int.random(in: 1000...9999))"

        let filters = app.buttons["devices.category.filter"]
        XCTAssertTrue(filters.waitForExistence(timeout: 5))
        filters.tap()
        XCTAssertTrue(app.navigationBars["Filter packs"].waitForExistence(timeout: 5))

        // Add a pack of 50
        app.navigationBars.buttons["filters.add"].tap()
        XCTAssertTrue(app.navigationBars["New Filter Pack"].waitForExistence(timeout: 5))
        let nameField = app.textFields["filterPack.name"]
        nameField.tap()
        nameField.typeText(name)
        app.buttons["50"].tap()
        attachScreenshot(named: "new-filter-pack")
        app.buttons["filterPack.save"].tap()
        XCTAssertTrue(app.staticTexts["Filter pack added"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, containing: "50 of 50 left").waitForExistence(timeout: 5))

        // −/+ adjust the count, within the pack
        let putBack = app.buttons["filters.putBackOne.\(name)"]
        XCTAssertFalse(putBack.isEnabled, "A full pack can't take filters back")
        app.buttons["filters.useOne.\(name)"].tap()
        XCTAssertTrue(element(app, containing: "49 of 50 left").waitForExistence(timeout: 5))
        attachScreenshot(named: "filter-packs")
        putBack.tap()
        XCTAssertTrue(element(app, containing: "50 of 50 left").waitForExistence(timeout: 5))

        // Edit what's left → running low
        element(app, containing: name).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Edit Filter Pack"].waitForExistence(timeout: 5))
        let left = app.textFields["Left"]
        XCTAssertTrue(left.waitForExistence(timeout: 5))
        left.doubleTap() // selects the number, so typing replaces it
        left.typeText("5")
        XCTAssertEqual(left.value as? String, "5")
        app.buttons["filterPack.save"].tap()
        XCTAssertTrue(app.staticTexts["Filter pack saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, containing: "5 of 50 left").waitForExistence(timeout: 5))

        // Remove
        element(app, containing: name).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Edit Filter Pack"].waitForExistence(timeout: 5))
        app.buttons["filterPack.delete"].tap()
        app.buttons["Remove"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Filter pack removed"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, containing: name).firstMatch.waitForNonExistence(timeout: 5))
    }

    /// The row's texts sit inside its button, so match on any element whose label contains `text`.
    private func element(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}
