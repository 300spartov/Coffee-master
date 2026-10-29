import Foundation
import OSLog

/// Categorised loggers. Filter in Console.app by subsystem = bundle identifier.
public enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "CoffeeMaster"

    public static let deepLink = Logger(subsystem: subsystem, category: "deeplink")
    public static let data = Logger(subsystem: subsystem, category: "data")
    public static let widgets = Logger(subsystem: subsystem, category: "widgets")
}
