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

    /// V60 setup: add a bag from the picker (it's picked), the water follows the dose, and Start
    /// carries the setup into the brew form. Removes the bag it added.
    func testSetupWithInlineAddedBean() {
        let app = XCUIApplication.launched()
        let bean = "UI Bean \(Int.random(in: 1000...9999))"
        openSetup(app, group: "alternative", method: "V60")

        // Picker → "+" → New Bean form inside the sheet → saved bag is picked
        app.buttons["setup.bean"].tap()
        XCTAssertTrue(app.navigationBars["Choose a bag"].waitForExistence(timeout: 5))
        attachScreenshot(named: "bean-picker")
        app.navigationBars["Choose a bag"].buttons["picker.add"].tap()
        let nameField = app.textFields["bean.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(bean)
        scrollTo(app.buttons["bean.save"], inForm: "bean.form", of: app).tap()
        XCTAssertTrue(app.staticTexts["\(bean) added"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, containing: bean).waitForExistence(timeout: 5), "The new bag should be picked")

        // Live calculation: 20 g × 16 = 320 ml
        let dose = app.textFields["setup.dose"]
        dose.doubleTap()
        dose.typeText("20")
        XCTAssertTrue(element(app, containing: "320").waitForExistence(timeout: 5))
        attachScreenshot(named: "setup")

        // Start → brew form prefilled with the bag
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        XCTAssertTrue(app.navigationBars["V60"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Bean name"].value as? String, bean)

        // Close the wizard and remove the bag
        app.navigationBars["V60"].buttons.firstMatch.tap()
        app.navigationBars["V60"].buttons.firstMatch.tap()
        app.navigationBars["Alternative"].buttons.firstMatch.tap()
        app.navigationBars["New Brew"].buttons["Cancel"].tap()
        app.tabBars.buttons["Beans"].tap()
        let row = element(app, containing: bean)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(row.waitForNonExistence(timeout: 5))
    }

    /// AeroPress shows position and filter count; Drip has no brewer or filter.
    func testSetupRowsFollowTheMethod() {
        let app = XCUIApplication.launched()
        openSetup(app, group: "alternative", method: "Aeropress")
        XCTAssertTrue(app.segmentedControls["setup.position"].exists)
        // The row may be prefilled with an AeroPress you own; the picker always asks for one.
        XCTAssertTrue(app.buttons["setup.dripper"].exists)
        app.buttons["setup.dripper"].tap()
        XCTAssertTrue(app.navigationBars["Choose Aeropress"].waitForExistence(timeout: 5))
        attachScreenshot(named: "aeropress-picker")
        app.swipeDown(velocity: .fast)
        XCTAssertTrue(app.navigationBars["Aeropress"].waitForExistence(timeout: 5))

        app.navigationBars["Aeropress"].buttons.firstMatch.tap()
        app.buttons["brew.method.Drip"].tap()
        XCTAssertTrue(app.navigationBars["Drip"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup.dripper"].exists)
        XCTAssertFalse(app.buttons["setup.filter"].exists)
        XCTAssertTrue(app.buttons["setup.grinder"].exists)
    }

    /// Start remembers the recipe: the next V60 setup opens with it. Puts the dose back afterwards.
    func testSetupIsRememberedForNextBrew() {
        let app = XCUIApplication.launched()
        setDoseAndStart(app, dose: "21")
        closeWizardFromBrewForm(app)

        openSetup(app, group: "alternative", method: "V60")
        XCTAssertEqual(app.textFields["setup.dose"].value as? String, "21")
        attachScreenshot(named: "remembered-setup")

        app.navigationBars["V60"].buttons.firstMatch.tap()
        app.navigationBars["Alternative"].buttons.firstMatch.tap()
        app.navigationBars["New Brew"].buttons["Cancel"].tap()
        setDoseAndStart(app, dose: "16")
        closeWizardFromBrewForm(app)
    }

    private func setDoseAndStart(_ app: XCUIApplication, dose: String) {
        openSetup(app, group: "alternative", method: "V60")
        let field = app.textFields["setup.dose"]
        field.doubleTap()
        field.typeText(dose)
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        XCTAssertTrue(app.textFields["Bean name"].waitForExistence(timeout: 5))
    }

    /// From the template brew form: back to setup, methods, step 1, then Cancel.
    private func closeWizardFromBrewForm(_ app: XCUIApplication) {
        app.navigationBars["V60"].buttons.firstMatch.tap()
        XCTAssertTrue(app.collectionViews["setup.form"].waitForExistence(timeout: 5))
        app.navigationBars["V60"].buttons.firstMatch.tap()
        app.navigationBars["Alternative"].buttons.firstMatch.tap()
        app.navigationBars["New Brew"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForNonExistence(timeout: 5))
    }

    private func openSetup(_ app: XCUIApplication, group: String, method: String) {
        app.brewButton.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
        app.buttons["brew.group.\(group)"].tap()
        app.buttons["brew.method.\(method)"].tap()
        XCTAssertTrue(app.navigationBars[method].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["setup.bean"].waitForExistence(timeout: 5))
    }

    private func element(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
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
