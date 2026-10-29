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

        // Delete
        app.staticTexts[name].tap()
        XCTAssertTrue(app.navigationBars["Edit Bean"].waitForExistence(timeout: 5))
        let delete = scrollTo(app.buttons["bean.delete"], in: app)
        delete.tap()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Bean deleted"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[name].waitForNonExistence(timeout: 5))
    }

    private func tapSave(in app: XCUIApplication) {
        scrollTo(app.buttons["bean.save"], in: app).tap()
    }

    /// The form is long and the keyboard may be up; dismiss it and scroll until `element` is tappable.
    @discardableResult
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        // With the sheet open there are two lists on screen; scroll the form, not the list behind it.
        let form = app.collectionViews["bean.form"]
        XCTAssertTrue(form.waitForExistence(timeout: 5), "Bean form not found")
        if app.keyboards.buttons["Return"].exists { app.keyboards.buttons["Return"].tap() }
        for _ in 0..<6 where !(element.exists && element.isHittable) {
            form.swipeUp(velocity: .slow)
        }
        if !element.isHittable {
            attachScreenshot(named: "unreachable")
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "hierarchy"
            tree.lifetime = .keepAlways
            add(tree)
        }
        XCTAssertTrue(element.isHittable, "\(element) isn't reachable")
        return element
    }
}
