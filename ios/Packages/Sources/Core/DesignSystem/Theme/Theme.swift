import SwiftUI
import UIKit

/// Entry point to the app's colors.
///
/// ```swift
/// Text("Hi").foregroundStyle(.theme.textSecondary)       // SwiftUI
/// view.backgroundColor = .theme.background                 // UIKit
/// ```
///
/// Colors are dynamic: they follow the system light/dark setting (or a window's
/// `overrideUserInterfaceStyle`) without any code in screens.
public enum Theme {
    /// The palette for a given appearance.
    public static func palette(for style: UIUserInterfaceStyle) -> ColorPalette {
        style == .dark ? dark : light
    }
}

/// Resolves any `ColorPalette` role into a dynamic UIKit color.
@dynamicMemberLookup
public struct ThemeUIColors: Sendable {
    public subscript(dynamicMember role: KeyPath<ColorPalette, ThemeColor>) -> UIColor {
        // Resolve both values now so the provider closure only captures plain values.
        let light = Theme.light[keyPath: role]
        let dark = Theme.dark[keyPath: role]
        return UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor
        }
    }
}

/// Resolves any `ColorPalette` role into a dynamic SwiftUI color.
@dynamicMemberLookup
public struct ThemeColors: Sendable {
    public subscript(dynamicMember role: KeyPath<ColorPalette, ThemeColor>) -> Color {
        Color(uiColor: ThemeUIColors()[dynamicMember: role])
    }
}

public extension UIColor {
    static var theme: ThemeUIColors { ThemeUIColors() }
}

public extension Color {
    static var theme: ThemeColors { ThemeColors() }
}

public extension ShapeStyle where Self == Color {
    /// Enables `.foregroundStyle(.theme.textSecondary)` / `.background(.theme.surface)`.
    static var theme: ThemeColors { ThemeColors() }
}

// MARK: - Screen backgrounds

public extension View {
    /// Plain screen: fills the safe area with `background`.
    func themedBackground() -> some View {
        background(Color.theme.background.ignoresSafeArea())
    }

    /// Grouped screen (`List`, `Form`, dashboards): replaces the system background with
    /// `groupedBackground`. Rows inside a `List` / `Form` should use `.themedRow()`.
    func themedGroupedBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.theme.groupedBackground.ignoresSafeArea())
    }

    /// Row background inside a themed `List` / `Form` section.
    func themedRow() -> some View {
        listRowBackground(Color.theme.surface)
    }
}
