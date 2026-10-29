import SwiftUI
import UIKit

/// Every color the app uses, by role. One instance per appearance: `Theme.light`, `Theme.dark`.
///
/// To change a color, edit `LightTheme.swift` / `DarkTheme.swift`.
/// To add a role, add a property here and give it a value in both themes —
/// it becomes available as `Color.theme.<role>` and `UIColor.theme.<role>` automatically.
public struct ColorPalette: Sendable {
    // MARK: Backgrounds

    /// Main screen background (plain screens).
    public var background: ThemeColor
    /// Background of grouped screens (lists, forms, dashboards).
    public var groupedBackground: ThemeColor
    /// Cards, list rows and tiles placed on `groupedBackground`.
    public var surface: ThemeColor
    /// Raised content: sheets, toasts, popovers, cards on `surface`.
    public var elevatedSurface: ThemeColor
    /// Subtle fill for inputs, unselected chips, tracks of bars and rings.
    public var fill: ThemeColor

    // MARK: Text & icons

    public var textPrimary: ThemeColor
    /// Subtitles, captions, metadata.
    public var textSecondary: ThemeColor
    /// Hints, placeholders, disabled content, chevrons.
    public var textTertiary: ThemeColor

    // MARK: Brand

    /// Buttons, links, selection, icons, tab bar selection.
    public var accent: ThemeColor
    /// Text and icons placed on `accent`.
    public var onAccent: ThemeColor
    /// Translucent accent for selected chips and soft highlights.
    public var accentSoft: ThemeColor

    // MARK: Status

    public var success: ThemeColor
    public var warning: ThemeColor
    public var error: ThemeColor
    public var info: ThemeColor

    // MARK: Lines & effects

    public var separator: ThemeColor
    public var shadow: ThemeColor

    // MARK: System bars

    public var navigationBar: ThemeColor
    public var tabBar: ThemeColor
    /// Unselected tab bar items.
    public var tabBarItem: ThemeColor

    public init(
        background: ThemeColor,
        groupedBackground: ThemeColor,
        surface: ThemeColor,
        elevatedSurface: ThemeColor,
        fill: ThemeColor,
        textPrimary: ThemeColor,
        textSecondary: ThemeColor,
        textTertiary: ThemeColor,
        accent: ThemeColor,
        onAccent: ThemeColor,
        accentSoft: ThemeColor,
        success: ThemeColor,
        warning: ThemeColor,
        error: ThemeColor,
        info: ThemeColor,
        separator: ThemeColor,
        shadow: ThemeColor,
        navigationBar: ThemeColor,
        tabBar: ThemeColor,
        tabBarItem: ThemeColor
    ) {
        self.background = background
        self.groupedBackground = groupedBackground
        self.surface = surface
        self.elevatedSurface = elevatedSurface
        self.fill = fill
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.accent = accent
        self.onAccent = onAccent
        self.accentSoft = accentSoft
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.separator = separator
        self.shadow = shadow
        self.navigationBar = navigationBar
        self.tabBar = tabBar
        self.tabBarItem = tabBarItem
    }
}

/// An sRGB color written as hex, e.g. `ThemeColor(0xD89858)` or `ThemeColor(0x3C3C43, alpha: 0.6)`.
public struct ThemeColor: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(_ hex: UInt32, alpha: Double = 1) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
        self.alpha = alpha
    }

    public var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
