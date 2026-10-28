import Foundation

/// App-wide constants shared by the app and all its extensions (widgets, live activities).
///
/// Keep in sync with:
/// - `Config/Info.plist` → `CFBundleURLSchemes` (`urlScheme`)
/// - Associated Domains entitlement → `applinks:<universalLinkHost>`
/// - App Groups entitlement (app + widget extension) → `appGroupID`
public enum AppConfiguration {
    public static let urlScheme = "coffeemaster"
    public static let universalLinkHost = "coffeemaster.app"
    public static let appGroupID = "group.com.coffeemaster.app"
}
