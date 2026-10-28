public extension Theme {
    /// Dark appearance. Neutrals currently mirror iOS system colors; the accent is the web app's amber (`--copper-lt`).
    static let dark = ColorPalette(
        background: ThemeColor(0x000000),
        groupedBackground: ThemeColor(0x000000),
        surface: ThemeColor(0x1C1C1E),
        elevatedSurface: ThemeColor(0x2C2C2E),

        textPrimary: ThemeColor(0xFFFFFF),
        textSecondary: ThemeColor(0xEBEBF5, alpha: 0.6),
        textTertiary: ThemeColor(0xEBEBF5, alpha: 0.3),

        accent: ThemeColor(0xD89858),
        onAccent: ThemeColor(0x1C130A),

        success: ThemeColor(0x30D158),
        warning: ThemeColor(0xFF9F0A),
        error: ThemeColor(0xFF453A),
        info: ThemeColor(0x0A84FF),

        separator: ThemeColor(0x38383A),
        shadow: ThemeColor(0x000000, alpha: 0.4),

        navigationBar: ThemeColor(0x000000),
        tabBar: ThemeColor(0x1C1C1E),
        tabBarItem: ThemeColor(0x8E8E93)
    )
}
