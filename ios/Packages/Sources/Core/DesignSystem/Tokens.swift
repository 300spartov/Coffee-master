import SwiftUI

public enum Spacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

public enum Radius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 20
}

// Colors: system semantic colors only (light + dark follow the system setting).
// The accent is the app's `AccentColor` asset (amber, from the web app) — use `.tint` / `Color.accentColor`.
