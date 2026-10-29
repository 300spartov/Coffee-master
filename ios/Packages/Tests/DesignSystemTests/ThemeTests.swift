import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

struct ThemeTests {
    private let lightTraits = UITraitCollection(userInterfaceStyle: .light)
    private let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

    @Test(arguments: ColorPalette.roles.map(\.name))
    func dynamicColorResolvesPerAppearance(_ name: String) throws {
        let role = try #require(ColorPalette.roles.first { $0.name == name }).keyPath
        let color = UIColor.theme[dynamicMember: role]

        #expect(color.resolvedColor(with: lightTraits) == Theme.light[keyPath: role].uiColor)
        #expect(color.resolvedColor(with: darkTraits) == Theme.dark[keyPath: role].uiColor)
    }

    /// `ColorPalette.roles` must list every property, or the gallery and this test miss a color.
    @Test func rolesCoverEveryPaletteProperty() {
        let properties = Mirror(reflecting: Theme.light).children.compactMap(\.label)

        #expect(Set(ColorPalette.roles.map(\.name)) == Set(properties))
        #expect(ColorPalette.roles.count == properties.count)
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
