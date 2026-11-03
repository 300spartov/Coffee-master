import XCTest

extension XCUIApplication {
    /// Launches the app in English, optionally opening `deepLink` (the Debug `-deeplink` argument,
    /// the same path as a cold-start URL). A brew left in progress by an earlier test is discarded
    /// unless `keepsBrewInProgress` (so one failed test doesn't reopen a brew in the next).
    @MainActor
    static func launched(deepLink: String? = nil, keepsBrewInProgress: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-app.language", "en"]
        if !keepsBrewInProgress { app.launchArguments += ["-discardBrewDraft", "YES"] }
        if let deepLink { app.launchArguments += ["-deeplink", deepLink] }
        app.launch()
        return app
    }

    var brewButton: XCUIElement { navigationBars.buttons["brew.button"] }

    /// Opens `url` from outside the app (like a widget or notification tap) while it keeps running,
    /// confirming the system "Open in …" prompt if it appears. Unlike `open(_:)`, the app's
    /// in-memory state (open sheets, flows) is preserved.
    func openFromOutside(_ url: URL) {
        XCUIDevice.shared.system.open(url)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let confirm = springboard.buttons["Open"]
        if confirm.waitForExistence(timeout: 3) { confirm.tap() }
        _ = wait(for: .runningForeground, timeout: 5)
    }
}

extension XCTestCase {
    /// Forms are long and the keyboard may be up: dismisses it and scrolls the form (accessibility id
    /// `formID`) until `element` is tappable. With a sheet open there are two lists on screen, so the
    /// form is named rather than guessed.
    @MainActor
    @discardableResult
    func scrollTo(_ element: XCUIElement, inForm formID: String, of app: XCUIApplication) -> XCUIElement {
        let form = app.collectionViews[formID]
        XCTAssertTrue(form.waitForExistence(timeout: 5), "Form \(formID) not found")
        // Close the keyboard first (Done above it, else Return), so it doesn't cover the element.
        if app.buttons["keyboard.done"].exists {
            app.buttons["keyboard.done"].tap()
        } else if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        }
        _ = app.keyboards.firstMatch.waitForNonExistence(timeout: 3)
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

    @MainActor
    func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
