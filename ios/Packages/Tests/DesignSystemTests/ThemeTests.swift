import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

struct ThemeTests {
    private let lightTraits = UITraitCollection(userInterfaceStyle: .light)
    private let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

    @Test(arguments: [
        \ColorPalette.background, \.groupedBackground, \.surface, \.elevatedSurface,
        \.textPrimary, \.textSecondary, \.textTertiary, \.accent, \.onAccent,
        \.success, \.warning, \.error, \.info, \.separator, \.shadow,
        \.navigationBar, \.tabBar, \.tabBarItem,
    ] as [KeyPath<ColorPalette, ThemeColor> & Sendable])
    func dynamicColorResolvesPerAppearance(_ role: KeyPath<ColorPalette, ThemeColor> & Sendable) {
        let color = UIColor.theme[dynamicMember: role]

        #expect(color.resolvedColor(with: lightTraits) == Theme.light[keyPath: role].uiColor)
        #expect(color.resolvedColor(with: darkTraits) == Theme.dark[keyPath: role].uiColor)
    }

    @Test func paletteForStyle() {
        #expect(Theme.palette(for: .dark).background == Theme.dark.background)
        #expect(Theme.palette(for: .light).background == Theme.light.background)
        #expect(Theme.palette(for: .unspecified).background == Theme.light.background)
    }

    @Test func hexParsing() {
        let color = ThemeColor(0xD89858, alpha: 0.5)

        #expect(color.red == 0xD8 / 255.0)
        #expect(color.green == 0x98 / 255.0)
        #expect(color.blue == 0x58 / 255.0)
        #expect(color.alpha == 0.5)
    }

    @Test func themesDifferWhereExpected() {
        #expect(Theme.light.background != Theme.dark.background)
        #expect(Theme.light.textPrimary != Theme.dark.textPrimary)
        #expect(Theme.light.accent != Theme.dark.accent)
    }
}
