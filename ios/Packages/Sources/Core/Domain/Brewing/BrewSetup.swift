import Foundation

/// The recipe chosen on the brew wizard's setup step (alternative methods), before the timer starts.
/// Defaults and limits match the web app.
public struct BrewSetup: Hashable, Codable, Sendable {
    public var method: BrewMethod
    public var bean: BeanReference?
    /// `nil` for Drip, which needs no separate brewer.
    public var dripper: GearReference?
    public var filter: GearReference?
    /// Wet (rinsed) or dry paper filter.
    public var isFilterRinsed: Bool
    public var grinder: GearReference?
    /// Grinder clicks / dial setting.
    public var grindSetting: Int
    /// °C.
    public var waterTemperature: Double
    public var doseGrams: Double
    /// Water-to-coffee ratio, e.g. `16` for 1:16.
    public var ratio: Double
    public var pours: Int
    /// AeroPress only.
    public var aeropress: AeroPressOptions?

    public init(method: BrewMethod) {
        self.method = method
        isFilterRinsed = true
        grindSetting = 28
        waterTemperature = method == .coldBrew ? 18 : 93
        doseGrams = 16
        ratio = 16
        pours = 3
        aeropress = method == .aeropress ? AeroPressOptions() : nil
    }
}

// MARK: - Limits

public extension BrewSetup {
    static let doseRange: ClosedRange<Double> = 1...300
    static let ratioRange: ClosedRange<Double> = 1...30
    static let poursRange: ClosedRange<Int> = 1...5
    static let grindRange: ClosedRange<Int> = 1...200
    static let aeropressFilterRange: ClosedRange<Int> = 1...4

    /// Cold brew steeps cold (10–30 °C); everything else uses hot water (80–100 °C).
    static func temperatureRange(for method: BrewMethod) -> ClosedRange<Double> {
        method == .coldBrew ? 10...30 : 80...100
    }

    /// A ratio inside `ratioRange`, rounded to one decimal (the web's `bRatioValidate`).
    static func validRatio(_ value: Double) -> Double {
        (value.clamped(to: ratioRange) * 10).rounded() / 10
    }

    /// This setup with every value inside its limits (fields are edited freely; this is what's brewed).
    func validated() -> BrewSetup {
        var setup = self
        setup.grindSetting = grindSetting.clamped(to: Self.grindRange)
        setup.waterTemperature = waterTemperature.clamped(to: Self.temperatureRange(for: method))
        setup.doseGrams = doseGrams.clamped(to: Self.doseRange)
        setup.ratio = Self.validRatio(ratio)
        setup.pours = pours.clamped(to: Self.poursRange)
        setup.aeropress?.filterCount = (aeropress?.filterCount ?? 1).clamped(to: Self.aeropressFilterRange)
        return setup
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - What the method needs

public extension BrewSetup {
    /// Drip machines are the brewer themselves.
    var usesDripper: Bool { method != .drip }
    var usesFilter: Bool { method != .drip }
}

// MARK: - Live calculation (the web's `bCalc`)

public extension BrewSetup {
    /// Total water to pour, ml.
    var waterMilliliters: Int { Int((doseGrams * ratio).rounded()) }
    /// Suggested bloom (first pour), ml: 3 × the dose.
    var bloomMilliliters: Int { Int((doseGrams * 3).rounded()) }
}

// MARK: - Recording

public extension BrewSetup {
    /// A brew made with this setup. Gear the method doesn't use is left out.
    func makeBrew(date: Date = .now, totalTime: TimeInterval? = nil, rating: Double, steps: [BrewStep] = []) -> Brew {
        Brew(
            date: date,
            method: method,
            bean: bean,
            dripper: usesDripper ? dripper : nil,
            grinder: grinder,
            grindSetting: grinder != nil ? grindSetting : nil,
            filter: usesFilter ? filter : nil,
            isFilterRinsed: usesFilter && filter != nil ? isFilterRinsed : nil,
            aeropress: aeropress,
            doseGrams: doseGrams,
            ratio: ratio,
            waterTemperature: waterTemperature,
            steps: steps,
            totalTime: totalTime,
            rating: rating
        )
    }
}
