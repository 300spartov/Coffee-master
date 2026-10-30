import XCTest

extension XCUIApplication {
    /// Launches the app in English, optionally opening `deepLink` (the Debug `-deeplink` argument,
    /// the same path as a cold-start URL).
    @MainActor
    static func launched(deepLink: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-app.language", "en"]
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
    @MainActor
    func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
