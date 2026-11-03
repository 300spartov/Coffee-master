import XCTest

/// The brew wizard: method pick, setup, pour-over timer, rating and result, espresso, the brew in
/// progress and its Live Activity.
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

        // Start → timer → Stop → rating, for this bag
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        brewThroughTimer(app)
        XCTAssertTrue(app.staticTexts[bean].waitForExistence(timeout: 5))

        // Close the wizard (without saving) and remove the bag
        closeWizardFromBrewForm(app)
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
        brewThroughTimer(app)
    }

    /// Back from the rating discards the brew, after asking.
    private func leaveRating(_ app: XCUIApplication) {
        app.navigationBars["Rate & Save"].buttons["rate.back"].tap()
        XCTAssertTrue(app.buttons["Discard"].waitForExistence(timeout: 5))
        app.buttons["Discard"].tap()
    }

    /// The shortest brew: one pour, then Stop; ends on the rating.
    private func brewThroughTimer(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["active.pour"].waitForExistence(timeout: 5))
        app.buttons["active.pour"].tap()
        app.buttons["active.stop"].tap()
        XCTAssertTrue(app.navigationBars["Rate & Save"].waitForExistence(timeout: 5))
    }

    /// From the rating (not saved): back to setup, methods, step 1, then Cancel closes the wizard.
    private func closeWizardFromBrewForm(_ app: XCUIApplication) {
        leaveRating(app)
        XCTAssertTrue(app.collectionViews["setup.form"].waitForExistence(timeout: 5))
        app.navigationBars["V60"].buttons.firstMatch.tap()
        app.navigationBars["Alternative"].buttons.firstMatch.tap()
        app.navigationBars["New Brew"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForNonExistence(timeout: 5))
    }

    /// The brew timer: pour (typed amount) → pause → stir → pour → stop, with the log and the
    /// form prefilled from it. Back before the first pour leaves without asking.
    func testActiveBrewLogsPoursAndActions() {
        let app = XCUIApplication.launched()
        openSetup(app, group: "alternative", method: "V60")
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        let pour = app.buttons["active.pour"]
        XCTAssertTrue(pour.waitForExistence(timeout: 5))

        // Back before starting: straight to the setup
        app.navigationBars["V60"].buttons["active.back"].tap()
        XCTAssertTrue(app.collectionViews["setup.form"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        XCTAssertTrue(pour.waitForExistence(timeout: 5))
        attachScreenshot(named: "active-ready")

        // Bloom: 60 ml
        pour.tap()
        let amount = app.textFields["active.pourMilliliters"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.typeText("60")
        sleep(1)
        app.buttons["active.pause"].tap()
        XCTAssertTrue(element(app, containing: "60").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["active.action.stir"].waitForExistence(timeout: 5))
        attachScreenshot(named: "active-pause")

        // Stir, second pour, stop
        app.buttons["active.action.stir"].tap()
        sleep(1)
        app.buttons["active.action.stir"].tap()
        pour.tap()
        // The planned count comes from the remembered setup, so only the pour number is fixed.
        XCTAssertTrue(app.staticTexts["active.pours"].label.hasPrefix("2 / "))
        app.buttons["active.pause"].tap()
        XCTAssertTrue(app.otherElements["active.log"].exists || element(app, containing: "Stir").exists)
        attachScreenshot(named: "active-log")
        app.swipeUp()
        app.buttons["active.stop"].tap()

        // The rating replaces the timer and has the flavor wheel; Back goes to the setup
        XCTAssertTrue(app.navigationBars["Rate & Save"].waitForExistence(timeout: 5))
        let fruit = app.buttons["wheel.Fruit"]
        for _ in 0..<6 where !fruit.isHittable { app.collectionViews["rate.form"].swipeUp(velocity: .slow) }
        fruit.tap()
        XCTAssertTrue(app.buttons["wheel.Citrus"].waitForExistence(timeout: 5))
        attachScreenshot(named: "pour-over-wheel")
        leaveRating(app)
        XCTAssertTrue(app.collectionViews["setup.form"].waitForExistence(timeout: 5))
    }

    /// Rate & save: the brew is saved, the result shows it, and "Go to Journal" lands on its card under
    /// Today (ROADMAP 3.1): details with the notes tab, like; then it's edited (3.2: the dose changed in
    /// the form, saved). Deletes the brew afterwards: setup may have picked your only bag, and the trash gives
    /// its coffee back.
    func testSavedBrewShowsResultAndJournal() {
        let app = XCUIApplication.launched()
        openSetup(app, group: "alternative", method: "Drip")
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        brewThroughTimer(app)
        let notes = app.textFields["tasting.notes"]
        let note = "UI brew \(Int.random(in: 1000...9999))"
        scrollTo(notes, inForm: "rate.form", of: app).tap()
        notes.typeText(note)
        attachScreenshot(named: "rate-keyboard")
        scrollTo(app.buttons["rate.save"], inForm: "rate.form", of: app).tap()

        XCTAssertTrue(app.staticTexts["Saved!"].waitForExistence(timeout: 5))
        attachScreenshot(named: "brew-result")
        app.buttons["result.journal"].tap()

        // Newest first: our brew is the top card, under Today.
        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 5))
        // Day headers are cells too: take the first card.
        let top = app.collectionViews.firstMatch.cells.containing(.button, identifier: "journal.brew").firstMatch
        XCTAssertTrue(top.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(identifier: "journal.day").firstMatch.label.hasPrefix("Today"))
        top.buttons["journal.details"].tap()
        app.segmentedControls["journal.tabs"].buttons["Notes"].tap()
        // Only touch the card if it really is ours, so a real brew is never changed.
        let ours = top.staticTexts[note]
        XCTAssertTrue(ours.waitForExistence(timeout: 5), "The saved Drip brew should be the newest")
        guard ours.exists else { return }
        let like = top.buttons["journal.like"]
        like.tap()
        XCTAssertTrue(like.wait(for: \.isSelected, toEqual: true, timeout: 5))
        attachScreenshot(named: "journal-card")

        // Edit: the card opens the form; the new dose shows on the card after saving.
        top.buttons["journal.brew"].tap()
        XCTAssertTrue(app.navigationBars["Edit Brew"].waitForExistence(timeout: 5))
        attachScreenshot(named: "brew-form")
        let dose = app.textFields["brewForm.dose"]
        dose.doubleTap()
        dose.typeText("19")
        scrollTo(app.buttons["brewForm.save"], inForm: "brewForm", of: app).tap()
        XCTAssertTrue(app.staticTexts["Brew updated"].waitForExistence(timeout: 5))
        XCTAssertTrue(top.staticTexts["19, g, Dose"].waitForExistence(timeout: 5), "The card should show the edited dose")

        // Delete it (trashing returns any stock it took).
        top.buttons["journal.brew"].swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(ours.waitForNonExistence(timeout: 5))
    }

    /// ROADMAP 2.8: a brew killed mid-pour comes back at launch, at the timer, with its clock running.
    func testBrewInProgressSurvivesAnAppKill() {
        let app = XCUIApplication.launched()
        openSetup(app, group: "alternative", method: "V60")
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        XCTAssertTrue(app.buttons["active.pour"].waitForExistence(timeout: 5))
        app.buttons["active.pour"].tap()
        sleep(2)

        app.terminate()
        let relaunched = XCUIApplication.launched(keepsBrewInProgress: true)

        XCTAssertTrue(relaunched.buttons["active.pause"].waitForExistence(timeout: 10), "The timer should be back")
        let time = relaunched.staticTexts["active.time"]
        XCTAssertTrue(time.waitForExistence(timeout: 5))
        XCTAssertNotEqual(time.label, "0:00", "The clock kept running while the app was closed")
        attachScreenshot(named: "restored-timer")

        // Discard it (a restored brew goes back to the method pick), so nothing is left for later launches.
        relaunched.navigationBars["V60"].buttons["active.back"].tap()
        relaunched.buttons["Discard"].tap()
        XCTAssertTrue(relaunched.buttons["brew.group.alternative"].waitForExistence(timeout: 5))
    }

    /// ROADMAP 2.4: a started brew shows its Live Activity outside the app (screenshot of the Home Screen
    /// with the Dynamic Island). Back on the started brew then asks before discarding it.
    func testLiveActivityShowsOutsideTheApp() {
        let app = XCUIApplication.launched()
        openSetup(app, group: "alternative", method: "V60")
        scrollTo(app.buttons["setup.save"], inForm: "setup.form", of: app).tap()
        XCTAssertTrue(app.buttons["active.pour"].waitForExistence(timeout: 5))
        app.buttons["active.pour"].tap()

        XCUIDevice.shared.press(.home)
        sleep(3)
        attachScreenshot(named: "live-activity-island")

        app.activate()
        XCTAssertTrue(app.buttons["active.pause"].waitForExistence(timeout: 5))
        app.navigationBars["V60"].buttons["active.back"].tap()
        XCTAssertTrue(app.staticTexts["Discard this brew?"].waitForExistence(timeout: 5))
        app.buttons["Discard"].tap()
        XCTAssertTrue(app.collectionViews["setup.form"].waitForExistence(timeout: 5))
    }

    /// Latte: setup → shot timer → milk → result. Doesn't save (saving is covered by unit tests),
    /// so the journal isn't touched.
    func testEspressoLatteGoesThroughShotMilkAndResult() {
        let app = XCUIApplication.launched()
        app.brewButton.tap()
        app.buttons["brew.group.espresso"].tap()
        app.buttons["brew.method.Latte"].tap()
        XCTAssertTrue(app.navigationBars["Latte"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["setup.espressoMachine"].waitForExistence(timeout: 5))
        attachScreenshot(named: "espresso-setup")
        scrollTo(app.buttons["espresso.save"], inForm: "espresso.form", of: app).tap()

        // Shot
        let start = app.buttons["espresso.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        sleep(2)
        attachScreenshot(named: "espresso-shot")
        app.buttons["espresso.stop"].tap()

        // Milk
        XCTAssertTrue(app.navigationBars["Milk"].waitForExistence(timeout: 5))
        let milk = app.textFields["espresso.milk"]
        milk.tap()
        milk.typeText("Oat")
        scrollTo(app.buttons["espresso.milk.save"], inForm: "espresso.milkForm", of: app).tap()

        // Result: the timer's seconds carried over
        XCTAssertTrue(app.navigationBars["Shot result"].waitForExistence(timeout: 5))
        let shotTime = app.textFields["espresso.shotTime"]
        XCTAssertTrue(shotTime.waitForExistence(timeout: 5))
        XCTAssertNotEqual(shotTime.value as? String, "0")
        XCTAssertTrue(app.buttons["espresso.result.save"].exists || app.collectionViews["espresso.resultForm"].exists)
        attachScreenshot(named: "espresso-result")

        // Flavor wheel: Fruit → Tropical → Mango is picked as a chip
        let fruit = app.buttons["wheel.Fruit"]
        for _ in 0..<6 where !fruit.isHittable { app.collectionViews["espresso.resultForm"].swipeUp(velocity: .slow) }
        fruit.tap()
        app.buttons["wheel.Tropical"].tap()
        app.buttons["wheel.Mango"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wheel.pick.Манго"].waitForExistence(timeout: 5))
        attachScreenshot(named: "flavor-wheel")
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
}
