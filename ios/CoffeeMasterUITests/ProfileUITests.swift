import XCTest

/// The Profile tab (ROADMAP 4.1): the card, Edit Profile, the avatar picker and Settings. Read-only:
/// it opens the forms and leaves without saving, so your profile isn't changed.
@MainActor
final class ProfileUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testProfileOpensItsScreens() {
        let app = XCUIApplication.launched()
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["profile.avatar"].exists)
        attachScreenshot(named: "profile")

        app.buttons["profile.edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit Profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["profileForm.name"].exists)
        attachScreenshot(named: "edit-profile")
        app.navigationBars["Edit Profile"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Edit Profile"].waitForNonExistence(timeout: 5))

        app.buttons["profile.avatar"].tap()
        XCTAssertTrue(app.navigationBars["Avatar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["avatar.🦊"].exists)
        XCTAssertTrue(app.buttons["avatar.photo"].exists, "A photo from the library can be the avatar")
        attachScreenshot(named: "avatar-picker")
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["avatar.customColor"].waitForExistence(timeout: 5), "Any color, after the presets")
        attachScreenshot(named: "avatar-colors")
        app.navigationBars["Avatar"].buttons["avatar.done"].tap()
        XCTAssertTrue(app.navigationBars["Avatar"].waitForNonExistence(timeout: 5))

        app.buttons["profile.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
}
