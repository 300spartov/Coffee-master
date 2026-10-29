import XCTest

/// UI tests for the app shell (tabs + Brew action). They drive the real app in the simulator.
/// Screenshots of key states are attached to the test results (Report navigator in Xcode).
@MainActor
final class AppShellUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testTabsAndBrewActionAreVisible() {
        let app = XCUIApplication.launched()

        for title in ["Journal", "Beans", "Devices", "Profile"] {
            XCTAssertTrue(app.tabBars.buttons[title].waitForExistence(timeout: 5), "Missing tab \(title)")
        }
        XCTAssertTrue(app.brewButton.waitForExistence(timeout: 5))
        attachScreenshot(named: "shell")
    }

    /// The Brew button lives on the Journal only.
    func testBrewButtonOnlyOnJournal() {
        let app = XCUIApplication.launched()
        XCTAssertTrue(app.brewButton.waitForExistence(timeout: 5))

        for title in ["Beans", "Devices", "Profile"] {
            app.tabBars.buttons[title].tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            XCTAssertFalse(app.brewButton.exists, "\(title) shouldn't show the Brew button")
        }

        app.tabBars.buttons["Journal"].tap()
        XCTAssertTrue(app.brewButton.waitForExistence(timeout: 5))
    }

    func testBrewActionOpensNewBrew() {
        let app = XCUIApplication.launched()

        app.brewButton.tap()

        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
        attachScreenshot(named: "new-brew")
    }

    /// Scrolling the Journal down minimizes the tab bar (iOS 26) and the Brew action stays reachable.
    func testTabBarMinimizesOnScrollAndBrewActionStays() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26, "Tab bar minimizing is iOS 26+")
        let app = XCUIApplication.launched()
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let beansTab = app.tabBars.buttons["Beans"]
        XCTAssertTrue(beansTab.isHittable)
        attachScreenshot(named: "before-scroll")

        list.swipeUp(velocity: .slow)
        list.swipeUp(velocity: .slow)

        // Minimized: only the selected tab remains, other tabs aren't tappable.
        XCTAssertTrue(beansTab.wait(for: \.isHittable, toEqual: false, timeout: 5))
        attachScreenshot(named: "after-scroll")

        XCTAssertTrue(app.brewButton.isHittable, "Brew action must stay reachable while the tab bar is minimized")
        app.brewButton.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
    }
}
