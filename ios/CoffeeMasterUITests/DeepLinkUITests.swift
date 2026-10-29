import XCTest

/// Deep link map v1, end to end: each link (passed as the Debug `-deeplink` launch argument,
/// the same path as a cold-start URL) must land on the right tab or screen.
@MainActor
final class DeepLinkUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func launch(_ link: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-app.language", "en", "-deeplink", link]
        app.launch()
        return app
    }

    private func assertSelectedTab(_ title: String, after link: String, file: StaticString = #filePath, line: UInt = #line) {
        let app = launch(link)
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "No tab \(title)", file: file, line: line)
        let selected = NSPredicate(format: "isSelected == true")
        expectation(for: selected, evaluatedWith: tab)
        waitForExpectations(timeout: 5)
        app.terminate()
    }

    func testTabLinks() {
        assertSelectedTab("Journal", after: "coffeemaster://journal")
        assertSelectedTab("Beans", after: "coffeemaster://beans")
        assertSelectedTab("Beans", after: "coffeemaster://beans/some-bean")
        assertSelectedTab("Devices", after: "coffeemaster://devices")
        assertSelectedTab("Profile", after: "coffeemaster://profile")
        assertSelectedTab("Profile", after: "coffeemaster://profile/achievements")
        assertSelectedTab("Profile", after: "coffeemaster://settings")
        assertSelectedTab("Journal", after: "https://coffeemaster.app/journal")
    }

    func testNewBrewLinkOpensBrewFlow() {
        let app = launch("coffeemaster://brew/new")
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
    }

    func testLegacyNewBrewLinkStillWorks() {
        let app = launch("coffeemaster://brews/new")
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
    }

    func testAboutLinkPushesAbout() {
        let app = launch("coffeemaster://settings/about")
        let about = app.navigationBars["About"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        // About hides the tab bar; its back button shows it was pushed on the Profile stack.
        XCTAssertTrue(about.buttons["Profile"].exists)
    }

    func testUnknownBrewShowsWarning() {
        let app = launch("coffeemaster://journal/not-a-brew-id")
        XCTAssertTrue(app.staticTexts["This brew no longer exists."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Journal"].isSelected)
    }
}
