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
