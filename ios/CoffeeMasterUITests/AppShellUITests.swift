import XCTest

/// UI tests for the app shell (tabs + Brew action). They drive the real app in the simulator.
///
/// Screenshots of key states are attached to the test results (Report navigator in Xcode).
@MainActor
final class AppShellUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-app.language", "en"]
    }

    func testTabsAndBrewActionAreVisible() throws {
        app.launch()

        for title in ["Journal", "Beans", "Devices", "Profile"] {
            XCTAssertTrue(app.tabBars.buttons[title].waitForExistence(timeout: 5), "Missing tab \(title)")
        }
        XCTAssertTrue(app.navigationBars.buttons["brew.button"].waitForExistence(timeout: 5))
        attachScreenshot(named: "shell")
    }

    func testBrewActionOpensNewBrew() throws {
        app.launch()

        app.navigationBars.buttons["brew.button"].tap()

        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
        attachScreenshot(named: "new-brew")
    }

    /// Scrolling the Journal down minimizes the tab bar (iOS 26) and the Brew action stays reachable.
    func testTabBarMinimizesOnScrollAndBrewActionStays() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26, "Tab bar minimizing is iOS 26+")
        app.launch()
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let beansTab = app.tabBars.buttons["Beans"]
        XCTAssertTrue(beansTab.isHittable)
        attachScreenshot(named: "before-scroll")

        list.swipeUp(velocity: .slow)
        list.swipeUp(velocity: .slow)

        // Minimized: only the selected tab remains, other tabs aren't tappable.
        let minimized = NSPredicate(format: "isHittable == false")
        expectation(for: minimized, evaluatedWith: beansTab)
        waitForExpectations(timeout: 5)
        attachScreenshot(named: "after-scroll")

        let brewButton = app.navigationBars.buttons["brew.button"]
        XCTAssertTrue(brewButton.isHittable, "Brew action must stay reachable while the tab bar is minimized")
        brewButton.tap()
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
