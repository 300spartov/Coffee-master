import Foundation
import AppCore

/// Two-way mapping between URLs and `DeepLink`.
///
/// Supported shapes (identical paths for both):
/// - Custom scheme: `coffeemaster://brews/42`
/// - Universal link: `https://coffeemaster.app/brews/42`
///
/// To add a route: add a `DeepLink` case, then extend `segments(for:)` and `route(_:)`.
/// The round-trip test in `DeepLinksTests` catches mismatches.
public struct DeepLinkParser: Sendable {
    public let scheme: String
    public let universalLinkHost: String

    public init(
        scheme: String = AppConfiguration.urlScheme,
        universalLinkHost: String = AppConfiguration.universalLinkHost
    ) {
        self.scheme = scheme.lowercased()
        self.universalLinkHost = universalLinkHost.lowercased()
    }

    // MARK: - URL → DeepLink

    public func parse(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlScheme = components.scheme?.lowercased()
        else { return nil }

        let pathSegments = components.path.split(separator: "/").map(String.init)

        if urlScheme == scheme {
            // For custom schemes the "host" is the first path segment: coffeemaster://brews/42
            let host = [components.host].compactMap { $0 }.filter { !$0.isEmpty }
            return route(host + pathSegments)
        }
        if urlScheme == "https", components.host?.lowercased() == universalLinkHost {
            return route(pathSegments)
        }
        return nil
    }

    // MARK: - DeepLink → URL

    public func url(for link: DeepLink) -> URL {
        let segments = segments(for: link)
        var components = URLComponents()
        components.scheme = scheme
        components.host = segments.first
        components.path = segments.dropFirst().map { "/" + $0 }.joined()
        guard let url = components.url else {
            preconditionFailure("Cannot build URL for \(link)")
        }
        return url
    }

    public func universalURL(for link: DeepLink) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = universalLinkHost
        components.path = segments(for: link).map { "/" + $0 }.joined()
        guard let url = components.url else {
            preconditionFailure("Cannot build universal URL for \(link)")
        }
        return url
    }

    // MARK: - Grammar

    private func segments(for link: DeepLink) -> [String] {
        switch link {
        case .brews: ["brews"]
        case .brewDetail(let id): ["brews", id]
        case .newBrew: ["brews", "new"]
        case .settings: ["settings"]
        case .about: ["settings", "about"]
        case .designSystem: ["settings", "design-system"]
        }
    }

    private func route(_ segments: [String]) -> DeepLink? {
        guard let first = segments.first?.lowercased() else { return .brews }
        let rest = Array(segments.dropFirst())

        switch (first, rest.count) {
        case ("brews", 0):
            return .brews
        case ("brews", 1):
            return rest[0].lowercased() == "new" ? .newBrew : .brewDetail(id: rest[0])
        case ("settings", 0):
            return .settings
        case ("settings", 1) where rest[0].lowercased() == "about":
            return .about
        case ("settings", 1) where rest[0].lowercased() == "design-system":
            return .designSystem
        default:
            return nil
        }
    }
}
