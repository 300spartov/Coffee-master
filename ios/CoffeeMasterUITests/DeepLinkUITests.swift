import XCTest

/// Deep link map v1, end to end: each link must land on the right tab or screen.
@MainActor
final class DeepLinkUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func assertSelectedTab(_ title: String, after link: String, file: StaticString = #filePath, line: UInt = #line) {
        let app = XCUIApplication.launched(deepLink: link)
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "No tab \(title)", file: file, line: line)
        XCTAssertTrue(tab.wait(for: \.isSelected, toEqual: true, timeout: 5), "\(link) didn't select \(title)", file: file, line: line)
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
        let app = XCUIApplication.launched(deepLink: "coffeemaster://brew/new")
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
    }

    func testLegacyNewBrewLinkStillWorks() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://brews/new")
        XCTAssertTrue(app.navigationBars["New Brew"].waitForExistence(timeout: 5))
    }

    func testAboutLinkPushesAbout() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://settings/about")
        let about = app.navigationBars["About"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        // About hides the tab bar; its back button shows it was pushed on the Profile stack.
        XCTAssertTrue(about.buttons["Profile"].exists)
    }

    func testUnknownBrewShowsWarning() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://journal/not-a-brew-id")
        XCTAssertTrue(app.staticTexts["This brew no longer exists."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Journal"].isSelected)
    }

    /// A well-formed id for a brew that doesn't exist behaves the same as a malformed one.
    func testMissingBrewShowsSameWarning() {
        let app = XCUIApplication.launched(deepLink: "coffeemaster://journal/00000000-0000-0000-0000-00000000dead")
        XCTAssertTrue(app.staticTexts["This brew no longer exists."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Journal"].isSelected)
    }
}
