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

public extension Color {
    static let brandPrimary = Color(red: 0.43, green: 0.27, blue: 0.17)
    static let brandSecondary = Color(red: 0.85, green: 0.62, blue: 0.36)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}
