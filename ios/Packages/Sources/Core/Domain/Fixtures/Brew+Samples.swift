import Foundation

// Fixtures for SwiftUI previews, seeding the in-memory store, and widget placeholders.

public extension Brew {
    static let samples: [Brew] = [
        Brew(
            id: "sample-1", method: .v60, beanName: "Ethiopia Yirgacheffe",
            doseGrams: 15, waterGrams: 250, brewTime: 180, rating: 5,
            date: Date(timeIntervalSinceNow: -3_600)
        ),
        Brew(
            id: "sample-2", method: .espresso, beanName: "Brazil Cerrado",
            doseGrams: 18, waterGrams: 36, brewTime: 28, rating: 4,
            date: Date(timeIntervalSinceNow: -86_400)
        ),
        Brew(
            id: "sample-3", method: .aeropress, beanName: "Kenya AA",
            doseGrams: 14, waterGrams: 200, brewTime: 120, rating: 3,
            date: Date(timeIntervalSinceNow: -172_800)
        ),
    ]
}

/// Read-only repository for SwiftUI previews.
public struct PreviewBrewRepository: BrewRepository {
    private let brews: [Brew]

    public init(brews: [Brew] = Brew.samples) {
        self.brews = brews
    }

    public func fetchAll() async throws -> [Brew] { brews }

    public func fetch(id: Brew.ID) async throws -> Brew {
        guard let brew = brews.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return brew
    }

    public func save(_ brew: Brew) async throws {}
    public func delete(id: Brew.ID) async throws {}
    public func changes() async -> AsyncStream<Void> { AsyncStream { _ in } }
}
