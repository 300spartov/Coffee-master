import Foundation
import AppCore

/// The recipe chosen on the espresso setup step. Defaults and limits match the web app.
public struct EspressoSetup: Hashable, Codable, Sendable {
    public var method: BrewMethod
    public var bean: BeanReference?
    public var machine: GearReference?
    public var grinder: GearReference?
    public var grindSetting: Int
    /// Accessories used (tamper, WDT, puck screen, frother, …).
    public var accessories: [GearReference]
    public var doseGrams: Double
    /// Yield-to-dose ratio, e.g. `2` for 1:2.
    public var ratio: Double
    /// °C.
    public var waterTemperature: Double
    public var pressureBar: Double

    public init(method: BrewMethod = .espresso) {
        self.method = method
        grindSetting = 12
        accessories = []
        doseGrams = 18
        ratio = 2
        waterTemperature = 93
        pressureBar = 9
    }
}

public extension EspressoSetup {
    static let doseRange: ClosedRange<Double> = 1...30
    static let ratioRange: ClosedRange<Double> = 1...5
    static let temperatureRange: ClosedRange<Double> = 84...100
    static let pressureRange: ClosedRange<Double> = 6...12
    /// The usual shot time the timer aims for (the web app's standard).
    static let targetShotTime: TimeInterval = 27

    /// Target yield, g, to one decimal.
    var targetYieldGrams: Double { (doseGrams * ratio).roundedToTenth }

    /// Cappuccino, flat white, latte: a milk step after the shot.
    var needsMilk: Bool { [.cappuccino, .flatWhite, .latte].contains(method) }
    /// Bumble, espresso tonic: an ice and mixer step after the shot.
    var needsIce: Bool { [.bumble, .espressoTonic].contains(method) }

    /// This setup with every value inside its limits.
    func validated() -> EspressoSetup {
        var setup = self
        setup.grindSetting = grindSetting.clamped(to: BrewSetup.grindRange)
        setup.doseGrams = doseGrams.clamped(to: Self.doseRange)
        setup.ratio = ratio.clamped(to: Self.ratioRange).roundedToTenth
        setup.waterTemperature = waterTemperature.clamped(to: Self.temperatureRange)
        setup.pressureBar = pressureBar.clamped(to: Self.pressureRange)
        return setup
    }

    /// The brew for a pulled shot. The ratio is the actual one when the shot was weighed.
    func makeBrew(
        date: Date = .now,
        shotTime: TimeInterval,
        actualYieldGrams: Double?,
        targetTDS: Double?,
        actualTDS: Double?,
        milk: MilkInfo?,
        ice: IceInfo?,
        tasting: BrewTasting
    ) -> Brew {
        let shot = EspressoShot(
            doseGrams: doseGrams,
            targetYieldGrams: targetYieldGrams,
            actualYieldGrams: actualYieldGrams.flatMap { $0 > 0 ? $0 : nil },
            shotTime: shotTime,
            targetTDS: targetTDS,
            actualTDS: actualTDS,
            pressureBar: pressureBar
        )
        return tasting.applied(to: Brew(
            date: date,
            method: method,
            bean: bean,
            grinder: grinder,
            grindSetting: grinder != nil ? grindSetting : nil,
            espressoMachine: machine,
            accessoryIDs: accessories.compactMap(\.id),
            doseGrams: doseGrams,
            ratio: doseGrams > 0 ? shot.yieldGrams / doseGrams : ratio,
            waterTemperature: waterTemperature,
            totalTime: shotTime,
            espresso: shot,
            milk: needsMilk ? milk.map { MilkInfo(name: $0.name.trimmed, temperature: $0.temperature, volumeMilliliters: $0.volumeMilliliters, frother: $0.frother) } : nil,
            ice: needsIce ? ice.map { IceInfo(cubes: $0.cubes, mixer: $0.mixer.trimmed) } : nil,
            rating: tasting.rating
        ))
    }
}
