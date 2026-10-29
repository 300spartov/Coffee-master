nonisolated public extension Theme {
    /// Light appearance. Neutrals currently mirror iOS system colors; the accent is the web app's amber,
    /// darkened for contrast on white.
    static let light = ColorPalette(
        background: ThemeColor(0xFFFFFF),
        groupedBackground: ThemeColor(0xF2F2F7),
        surface: ThemeColor(0xFFFFFF),
        elevatedSurface: ThemeColor(0xFFFFFF),
        fill: ThemeColor(0x767680, alpha: 0.12),

        textPrimary: ThemeColor(0x000000),
        textSecondary: ThemeColor(0x3C3C43, alpha: 0.6),
        textTertiary: ThemeColor(0x3C3C43, alpha: 0.3),

        accent: ThemeColor(0xC27A2C),
        onAccent: ThemeColor(0x1C130A),
        accentSoft: ThemeColor(0xC27A2C, alpha: 0.16),

        success: ThemeColor(0x34C759),
        warning: ThemeColor(0xFF9500),
        error: ThemeColor(0xFF3B30),
        info: ThemeColor(0x007AFF),

        separator: ThemeColor(0xC6C6C8),
        shadow: ThemeColor(0x000000, alpha: 0.15),

        navigationBar: ThemeColor(0xF2F2F7),
        tabBar: ThemeColor(0xF9F9F9),
        tabBarItem: ThemeColor(0x8E8E93)
    )
}
