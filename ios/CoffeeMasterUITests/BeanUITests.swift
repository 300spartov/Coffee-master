import XCTest

/// Bean add → edit → delete, end to end. Uses a unique name and deletes it again,
/// so it leaves the simulator's data as it found it.
@MainActor
final class BeanUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testAddEditAndDeleteBean() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://beans")
        let name = "UI Test Bean \(Int.random(in: 1000...9999))"

        // Add
        app.navigationBars.buttons["beans.add"].tap()
        XCTAssertTrue(app.navigationBars["New Bean"].waitForExistence(timeout: 5))
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText(name)
        tapSave(in: app)
        XCTAssertTrue(app.staticTexts["Bean added"].waitForExistence(timeout: 5))
        let row = app.staticTexts[name]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        attachScreenshot(named: "bean-added")

        // Edit
        row.tap()
        XCTAssertTrue(app.navigationBars["Edit Bean"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Name"].value as? String, name)
        let roasterField = app.textFields["Roaster"]
        roasterField.tap()
        roasterField.typeText("UI Roaster")
        attachScreenshot(named: "bean-edit")
        tapSave(in: app)
        XCTAssertTrue(app.staticTexts["Bean saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Roaster"].waitForExistence(timeout: 5))

        // Delete. First, suggestions sit in the bar above the keyboard: shorten the name, pick it back.
        app.staticTexts[name].tap()
        XCTAssertTrue(app.navigationBars["Edit Bean"].waitForExistence(timeout: 5))
        let nameAgain = app.textFields["Name"]
        nameAgain.tap()
        nameAgain.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2))
        let suggestion = app.buttons.matching(NSPredicate(format: "identifier == 'keyboard.suggestion' AND label == %@", name)).firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "The full name is suggested in the keyboard bar")
        attachScreenshot(named: "bean-suggestion")
        suggestion.tap()
        XCTAssertEqual(nameAgain.value as? String, name)
        let delete = scrollTo(app.buttons["bean.delete"], inForm: "bean.form", of: app)
        delete.tap()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Bean deleted"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[name].waitForNonExistence(timeout: 5))
    }

    private func tapSave(in app: XCUIApplication) {
        scrollTo(app.buttons["bean.save"], inForm: "bean.form", of: app).tap()
    }
}
