import XCTest

/// Devices tab end to end: category → search → quick-add → catalog toggle → edit → remove.
/// Uses a unique name and removes everything it adds.
@MainActor
final class DeviceUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testCatalogQuickAddToggleEditAndRemove() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://devices")
        let custom = "UI Kettle \(Int.random(in: 1000...9999))"

        // Category
        let kettles = app.buttons["devices.category.kettle"]
        XCTAssertTrue(kettles.waitForExistence(timeout: 5))
        attachScreenshot(named: "categories")
        kettles.tap()
        XCTAssertTrue(app.navigationBars["Kettles"].waitForExistence(timeout: 5))

        // Search + quick-add something the catalog doesn't have
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText(custom)
        let quickAdd = app.buttons["devices.quickAdd"]
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 5))
        attachScreenshot(named: "quick-add")
        quickAdd.tap()
        XCTAssertTrue(app.staticTexts[custom].waitForExistence(timeout: 5))
        XCTAssertFalse(quickAdd.exists, "Quick-add should disappear once the device is owned")

        // Catalog toggle: add, then remove a catalog kettle
        search.clearText()
        search.typeText("Takahiro")
        let toggle = app.buttons["devices.toggle.Takahiro"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let wasOwned = toggle.label.hasPrefix("Remove")
        toggle.tap()
        XCTAssertTrue(toggle.wait(for: \.label, toEqual: wasOwned ? "Add Takahiro" : "Remove Takahiro", timeout: 5))
        toggle.tap() // restore
        XCTAssertTrue(toggle.wait(for: \.label, toEqual: wasOwned ? "Remove Takahiro" : "Add Takahiro", timeout: 5))

        // Edit the custom kettle, then remove it
        search.clearText()
        search.typeText(custom)
        app.staticTexts[custom].tap()
        XCTAssertTrue(app.navigationBars["Edit Device"].waitForExistence(timeout: 5))
        attachScreenshot(named: "edit-device")
        app.buttons["device.delete"].tap()
        app.buttons["Remove"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Device removed"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[custom].waitForNonExistence(timeout: 5))
    }

    /// The search bar is visible when the category opens, collapses while scrolling the list,
    /// and comes back at the top.
    func testSearchBarCollapsesWhileScrolling() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://devices")
        app.buttons["devices.category.grinder"].tap()
        XCTAssertTrue(app.navigationBars["Grinders"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertTrue(search.isHittable, "Search should be visible when the screen opens")

        let list = app.collectionViews.firstMatch
        list.swipeUp(velocity: .slow)
        XCTAssertTrue(search.wait(for: \.isHittable, toEqual: false, timeout: 5), "Search should collapse while scrolling")
        attachScreenshot(named: "search-collapsed")

        list.swipeDown(velocity: .fast)
        list.swipeDown(velocity: .fast)
        XCTAssertTrue(search.wait(for: \.isHittable, toEqual: true, timeout: 5), "Search should come back at the top")
    }
}

private extension XCUIElement {
    /// Clears a search or text field via its clear button (or by deleting characters).
    func clearText() {
        if buttons["Clear text"].exists {
            buttons["Clear text"].tap()
        } else if let text = value as? String, !text.isEmpty {
            tap()
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count))
        }
    }
}

/// Regression: when a deep link closes a sheet, the flow must still be able to open it again.
@MainActor
final class SheetReopenUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testDeviceSheetReopensAfterDeepLinkClosedIt() throws {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://devices")
        app.buttons["devices.category.kettle"].tap()
        app.navigationBars.buttons["devices.add"].tap()
        XCTAssertTrue(app.navigationBars["New Device"].waitForExistence(timeout: 5))

        app.openFromOutside(try XCTUnwrap(URL(string: "coffeemaster://devices")))
        XCTAssertTrue(app.buttons["devices.category.kettle"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["New Device"].exists)

        app.buttons["devices.category.kettle"].tap()
        app.navigationBars.buttons["devices.add"].tap()
        XCTAssertTrue(app.navigationBars["New Device"].waitForExistence(timeout: 5), "Sheet didn't reopen")
    }

    func testBrewScreenReopensAfterDeepLinkClosedIt() throws {
        let app = XCUIApplication.launched()
        app.brewButton.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))

        app.openFromOutside(try XCTUnwrap(URL(string: "coffeemaster://journal")))
        XCTAssertTrue(app.navigationBars["New Brew"].waitForNonExistence(timeout: 5))

        XCTAssertTrue(app.brewButton.waitForExistence(timeout: 5))
        app.brewButton.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5), "Brew screen didn't reopen")
    }
}
