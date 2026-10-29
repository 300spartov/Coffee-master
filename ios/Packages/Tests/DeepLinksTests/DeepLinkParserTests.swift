import Foundation
import Testing
@testable import DeepLinks

struct DeepLinkParserTests {
    private let parser = DeepLinkParser(scheme: "coffeemaster", universalLinkHost: "coffeemaster.app")

    private static let allLinks: [DeepLink] = [
        .journal, .brewDetail(id: "42"), .newBrew, .beans, .beanDetail(id: "7"), .devices,
        .profile, .achievements, .settings, .about, .designSystem,
    ]

    @Test(arguments: [
        ("coffeemaster://journal", DeepLink.journal),
        ("coffeemaster://", .journal),
        ("coffeemaster://journal/42", .brewDetail(id: "42")),
        ("coffeemaster://brew/new", .newBrew),
        ("coffeemaster://beans", .beans),
        ("coffeemaster://beans/7", .beanDetail(id: "7")),
        ("coffeemaster://devices", .devices),
        ("coffeemaster://profile", .profile),
        ("coffeemaster://profile/achievements", .achievements),
        ("coffeemaster://settings", .settings),
        ("coffeemaster://settings/about", .about),
        ("coffeemaster://settings/design-system", .designSystem),
        ("COFFEEMASTER://Journal/AbC", .brewDetail(id: "AbC")),
        ("https://coffeemaster.app/journal/42", .brewDetail(id: "42")),
        ("https://CoffeeMaster.app/profile/Achievements", .achievements),
    ])
    func parsesSupportedURLs(_ string: String, expected: DeepLink) throws {
        let url = try #require(URL(string: string))
        #expect(parser.parse(url) == expected)
    }

    @Test(arguments: [
        ("coffeemaster://brews", DeepLink.journal),
        ("coffeemaster://brews/42", .brewDetail(id: "42")),
        ("coffeemaster://brews/new", .newBrew),
        ("https://coffeemaster.app/brews/new", .newBrew),
    ])
    func acceptsLegacyPaths(_ string: String, expected: DeepLink) throws {
        let url = try #require(URL(string: string))
        #expect(parser.parse(url) == expected)
    }

    @Test(arguments: [
        "coffeemaster://unknown",
        "coffeemaster://journal/42/extra",
        "coffeemaster://brew",
        "coffeemaster://brew/other",
        "coffeemaster://devices/1",
        "coffeemaster://profile/unknown",
        "coffeemaster://settings/unknown",
        "https://evil.example.com/journal/42",
        "http://coffeemaster.app/journal/42",
        "mailto:hello@coffeemaster.app",
    ])
    func rejectsUnsupportedURLs(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(parser.parse(url) == nil)
    }

    @Test(arguments: allLinks)
    func customSchemeRoundTrip(_ link: DeepLink) {
        #expect(parser.parse(parser.url(for: link)) == link)
    }

    @Test(arguments: allLinks)
    func universalLinkRoundTrip(_ link: DeepLink) {
        #expect(parser.parse(parser.universalURL(for: link)) == link)
    }

    @Test func buildsCurrentPathsOnly() {
        #expect(parser.url(for: .brewDetail(id: "42")).absoluteString == "coffeemaster://journal/42")
        #expect(parser.url(for: .newBrew).absoluteString == "coffeemaster://brew/new")
        #expect(parser.universalURL(for: .achievements).absoluteString == "https://coffeemaster.app/profile/achievements")
    }
}
