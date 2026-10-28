import Foundation
import Domain
import DeepLinks

/// Small, Codable projection of app data that widgets render.
/// Widgets don't hit the repository — the app writes this snapshot into the App Group container.
public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public struct Item: Codable, Sendable, Equatable, Identifiable {
        public let id: String
        public let beanName: String
        public let methodTitle: String
        public let rating: Int
        public let date: Date

        /// Pass to `widgetURL(_:)` / `Link` so a tap opens the brew detail.
        public var deepLinkURL: URL {
            DeepLink.brewDetail(id: id).url
        }
    }

    public let items: [Item]
    public let generatedAt: Date

    public init(brews: [Brew], limit: Int = 3, generatedAt: Date = .now) {
        items = brews.prefix(limit).map {
            Item(id: $0.id, beanName: $0.beanName, methodTitle: $0.method.title, rating: $0.rating, date: $0.date)
        }
        self.generatedAt = generatedAt
    }

    public static let placeholder = WidgetSnapshot(brews: Brew.samples)
}
