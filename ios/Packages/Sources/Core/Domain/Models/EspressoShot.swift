import Foundation

public struct EspressoShot: Hashable, Codable, Sendable {
    public var doseGrams: Double
    public var targetYieldGrams: Double
    /// `nil` when the user didn't weigh the shot.
    public var actualYieldGrams: Double?
    public var shotTime: TimeInterval
    public var targetTDS: Double?
    public var actualTDS: Double?
    public var pressureBar: Double?

    public init(
        doseGrams: Double,
        targetYieldGrams: Double,
        actualYieldGrams: Double? = nil,
        shotTime: TimeInterval,
        targetTDS: Double? = nil,
        actualTDS: Double? = nil,
        pressureBar: Double? = nil
    ) {
        self.doseGrams = doseGrams
        self.targetYieldGrams = targetYieldGrams
        self.actualYieldGrams = actualYieldGrams
        self.shotTime = shotTime
        self.targetTDS = targetTDS
        self.actualTDS = actualTDS
        self.pressureBar = pressureBar
    }

    /// Actual yield if weighed, otherwise the target.
    public var yieldGrams: Double { actualYieldGrams ?? targetYieldGrams }
}

/// Milk component of a milk drink (cappuccino, latte, …).
public struct MilkInfo: Hashable, Codable, Sendable {
    public var name: String
    public var temperature: Double?
    public var volumeMilliliters: Double?
    /// Frother device name, or the machine's steam wand.
    public var frother: String

    public init(name: String, temperature: Double? = nil, volumeMilliliters: Double? = nil, frother: String = "") {
        self.name = name
        self.temperature = temperature
        self.volumeMilliliters = volumeMilliliters
        self.frother = frother
    }
}

/// Ice / mixer component of cold drinks (Bumble, Espresso Tonic, …).
public struct IceInfo: Hashable, Codable, Sendable {
    public var amountGrams: Double?
    /// Juice, tonic, etc.
    public var mixer: String

    public init(amountGrams: Double? = nil, mixer: String = "") {
        self.amountGrams = amountGrams
        self.mixer = mixer
    }
}
