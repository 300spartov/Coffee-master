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
        /// 0...10
        public let rating: Double
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
            Item(id: $0.id.uuidString, beanName: $0.bean?.name ?? "", methodTitle: $0.method.rawValue, rating: $0.rating, date: $0.date)
        }
        self.generatedAt = generatedAt
    }

    public static let placeholder = WidgetSnapshot(brews: Brew.samples)
}
