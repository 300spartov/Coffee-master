import Foundation
import Testing
@testable import DeepLinks

struct DeepLinkParserTests {
    private let parser = DeepLinkParser(scheme: "coffeemaster", universalLinkHost: "coffeemaster.app")

    private static let allLinks: [DeepLink] = [
        .brews, .brewDetail(id: "42"), .newBrew, .settings, .about,
    ]

    @Test(arguments: [
        ("coffeemaster://brews", DeepLink.brews),
        ("coffeemaster://", .brews),
        ("coffeemaster://brews/42", .brewDetail(id: "42")),
        ("coffeemaster://brews/new", .newBrew),
        ("coffeemaster://settings", .settings),
        ("coffeemaster://settings/about", .about),
        ("COFFEEMASTER://Brews/AbC", .brewDetail(id: "AbC")),
        ("https://coffeemaster.app/brews/42", .brewDetail(id: "42")),
        ("https://CoffeeMaster.app/settings/about", .about),
    ])
    func parsesSupportedURLs(_ string: String, expected: DeepLink) throws {
        let url = try #require(URL(string: string))
        #expect(parser.parse(url) == expected)
    }

    @Test(arguments: [
        "coffeemaster://unknown",
        "coffeemaster://brews/42/extra",
        "coffeemaster://settings/unknown",
        "https://evil.example.com/brews/42",
        "http://coffeemaster.app/brews/42",
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

    @Test func buildsExpectedURL() {
        #expect(parser.url(for: .brewDetail(id: "42")).absoluteString == "coffeemaster://brews/42")
        #expect(parser.universalURL(for: .about).absoluteString == "https://coffeemaster.app/settings/about")
    }
}
