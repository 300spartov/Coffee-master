import UIKit
import DesignSystem

/// Applies the theme to UIKit chrome. Call once per window, before it becomes visible.
public enum ThemeAppearance {
    public static func apply(to window: UIWindow) {
        // SwiftUI `.tint` inside hosting controllers inherits this.
        window.tintColor = .theme.accent
        window.backgroundColor = .theme.background
        configureNavigationBar()
        configureTabBar()
    }

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        if #available(iOS 26, *) {
            // Liquid Glass: an opaque background hides large titles, and the system draws the bar as glass.
            // `navigationBar` color applies on iOS 17–18 only.
            appearance.configureWithDefaultBackground()
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .theme.navigationBar
            appearance.shadowColor = .clear
        }
        appearance.titleTextAttributes = [.foregroundColor: UIColor.theme.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.theme.textPrimary]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.compactAppearance = appearance
        bar.scrollEdgeAppearance = appearance
    }

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        if #unavailable(iOS 26) {
            // iOS 26 draws the tab bar as floating glass; `tabBar` color applies on iOS 17–18.
            appearance.backgroundColor = .theme.tabBar
        }
        for itemAppearance in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            itemAppearance.normal.iconColor = .theme.tabBarItem
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.theme.tabBarItem]
            itemAppearance.selected.iconColor = .theme.accent
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.theme.accent]
        }

        let bar = UITabBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.tintColor = .theme.accent
    }
}
