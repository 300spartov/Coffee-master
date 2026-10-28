import Foundation

// Fixtures for SwiftUI previews, seeding the in-memory store, tests and widget placeholders.
// Stable UUIDs so previews and deep links (`coffeemaster://brews/<id>`) are reproducible.

public extension UUID {
    /// `00000000-0000-0000-0000-<n padded to 12 digits>` — for fixtures only.
    static func fixture(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!
    }
}

public extension Bean {
    static let samples: [Bean] = [
        Bean(
            id: .fixture(101), name: "Ethiopia Yirgacheffe", roaster: "Wonder&Full",
            totalGrams: 250, remainingGrams: 160, country: "Ethiopia", process: .washed,
            score: 87, descriptors: "Jasmine, bergamot, black tea", roastProfile: .filter
        ),
        Bean(
            id: .fixture(102), name: "Brazil Cerrado", roaster: "Penyora",
            totalGrams: 1_000, remainingGrams: 420, country: "Brazil", process: .natural,
            score: 84, descriptors: "Chocolate, hazelnut", roastProfile: .espresso
        ),
    ]
}

public extension Brew {
    static let samples: [Brew] = [
        Brew(
            id: .fixture(1),
            date: Date(timeIntervalSinceNow: -3_600),
            method: .v60,
            bean: BeanReference(beanID: .fixture(101), name: "Ethiopia Yirgacheffe", roaster: "Wonder&Full", roastProfile: .filter),
            dripper: GearReference(name: "Hario V60 02"),
            grinder: GearReference(name: "Comandante C40 MK4"),
            grindSetting: 24,
            filter: GearReference(name: "Cafec Abaca"),
            isFilterRinsed: true,
            doseGrams: 15,
            ratio: 16,
            waterTemperature: 93,
            steps: [
                BrewStep(kind: .pour(milliliters: 50), start: 0, duration: 10),
                BrewStep(kind: .pause, start: 10, duration: 35),
                BrewStep(kind: .pour(milliliters: 100), start: 45, duration: 20),
                BrewStep(kind: .action(.swirl), start: 65, duration: 5),
                BrewStep(kind: .pour(milliliters: 90), start: 70, duration: 20),
            ],
            totalTime: 180,
            rating: 9.2,
            flavors: ["Жасмин", "Бергамот"],
            aromas: ["Чай"],
            notes: "Sweet when cooling."
        ),
        Brew(
            id: .fixture(2),
            date: Date(timeIntervalSinceNow: -86_400),
            method: .cappuccino,
            bean: BeanReference(beanID: .fixture(102), name: "Brazil Cerrado", roaster: "Penyora", roastProfile: .espresso),
            grinder: GearReference(name: "Niche Zero"),
            grindSetting: 12,
            espressoMachine: GearReference(name: "Gaggia Classic Pro"),
            doseGrams: 18,
            ratio: 2,
            waterTemperature: 94,
            totalTime: 28,
            espresso: EspressoShot(doseGrams: 18, targetYieldGrams: 36, actualYieldGrams: 37.5, shotTime: 28, pressureBar: 9),
            milk: MilkInfo(name: "Whole milk", temperature: 60, volumeMilliliters: 120, frother: "Steam wand"),
            rating: 8,
            flavors: ["Шоколад"]
        ),
        Brew(
            id: .fixture(3),
            date: Date(timeIntervalSinceNow: -172_800),
            method: "Flat White",
            doseGrams: 18,
            ratio: 2,
            beverageVolume: 180,
            rating: 7.5,
            notes: "Nice café downtown.",
            origin: .cafe(place: "Blackwood Coffee"),
            isManual: true
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
