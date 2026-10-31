import XCTest

/// Brew wizard, step 1–2: Brew → Alternative / Espresso → a method → the brew form for that method.
@MainActor
final class BrewUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testPickAlternativeAndEspressoMethods() {
        let app = XCUIApplication.launched()
        app.brewButton.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["What’s brewing today?"].exists)
        attachScreenshot(named: "method-groups")

        // Alternative → V60 opens the form with V60 picked
        app.buttons["brew.group.alternative"].tap()
        XCTAssertTrue(app.navigationBars["Alternative"].waitForExistence(timeout: 5))
        for method in ["V60", "Aeropress", "Chemex", "French Press", "Drip", "Cold Brew", "Batch Brewing"] {
            XCTAssertTrue(app.buttons["brew.method.\(method)"].exists, "Missing \(method)")
        }
        attachScreenshot(named: "alternative-methods")
        app.buttons["brew.method.V60"].tap()
        XCTAssertTrue(app.navigationBars["V60"].waitForExistence(timeout: 5))

        // Back to step 1, then Espresso → Latte
        app.navigationBars["V60"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Alternative"].waitForExistence(timeout: 5))
        app.navigationBars["Alternative"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
        app.buttons["brew.group.espresso"].tap()
        XCTAssertTrue(app.navigationBars["Espresso"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'brew.method.'")).count, 6)
        app.buttons["brew.method.Latte"].tap()
        XCTAssertTrue(app.navigationBars["Latte"].waitForExistence(timeout: 5))
    }

    func testCancelClosesWizard() {
        let app = XCUIApplication.launched()
        app.brewButton.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))

        app.navigationBars["New Brew"].buttons["Cancel"].tap()

        XCTAssertTrue(app.navigationBars["New Brew"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.brewButton.waitForExistence(timeout: 5))
    }
}
