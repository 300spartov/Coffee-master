import Foundation
import Domain
import BrewKit
import DesignSystem

/// 2–4 brews side by side (web: `compare.js`): each brew's steps on its own clock, the water it took over
/// time, and the parameters that differ.
nonisolated struct Comparison: Equatable {
    /// One compared brew.
    struct Entry: Identifiable, Equatable {
        let brew: Brew
        /// Its place in the comparison: its color.
        let index: Int
        /// The timer's steps, back to back; an espresso without them is its shot (one pour of the yield).
        let steps: [BrewStep]
        /// The water poured over time: a slope while pouring, flat during pauses and actions.
        let curve: [CurvePoint]
        /// Actions (stir, swirl, …) at their middle, on the curve.
        let actions: [CurvePoint]

        var id: Brew.ID { brew.id }
        var totalTime: TimeInterval { steps.last?.end ?? 0 }

        /// Water poured by `seconds` (along the curve; the total once it's over).
        func milliliters(at seconds: TimeInterval) -> Double {
            guard let next = curve.firstIndex(where: { $0.seconds >= seconds }) else { return curve.last?.milliliters ?? 0 }
            guard next > 0 else { return curve[next].milliliters }
            let (from, to) = (curve[next - 1], curve[next])
            let span = to.seconds - from.seconds
            return span > 0 ? from.milliliters + (to.milliliters - from.milliliters) * (seconds - from.seconds) / span : to.milliliters
        }

        init(brew: Brew, index: Int) {
            self.brew = brew
            self.index = index
            if brew.steps.isEmpty, let shot = brew.espresso {
                steps = [BrewStep(kind: .pour(milliliters: shot.yieldGrams), start: 0, duration: shot.shotTime)]
            } else {
                steps = brew.steps.resequenced()
            }
            var curve = [CurvePoint(seconds: steps.first?.start ?? 0, milliliters: 0)], actions: [CurvePoint] = []
            var milliliters = 0.0
            for step in steps {
                if case .action = step.kind { actions.append(CurvePoint(seconds: step.start + step.duration / 2, milliliters: milliliters)) }
                milliliters += step.pouredMilliliters
                curve.append(CurvePoint(seconds: step.end, milliliters: milliliters))
            }
            self.curve = curve
            self.actions = actions
        }
    }

    /// The brew whose curve passes nearest a tap on the curve chart (`seconds`, `milliliters`).
    func entry(nearestSeconds seconds: TimeInterval, milliliters: Double) -> Entry? {
        entries.min { abs($0.milliliters(at: seconds) - milliliters) < abs($1.milliliters(at: seconds) - milliliters) }
    }

    /// The ring under a tap `distance` from the rings' center, rings `pitch` apart from the outer
    /// one at `outerRadius` (the first brew outside), each `width` wide.
    func ringEntry(atDistance distance: Double, outerRadius: Double, pitch: Double, width: Double) -> Entry? {
        entries.first { abs(distance - (outerRadius - Double($0.index) * pitch)) <= width / 2 + (pitch - width) / 2 }
    }

    struct CurvePoint: Equatable, Hashable {
        let seconds: TimeInterval
        let milliliters: Double
    }

    /// A parameters table row; `differs` marks the values found in no other brew (web: orange).
    struct Row: Identifiable, Equatable {
        let title: String
        let values: [String]

        var id: String { title }

        var differs: [Bool] {
            let same = Set(values).count == 1
            return values.map { value in !same && values.filter { $0 == value }.count == 1 }
        }
    }

    let entries: [Entry]

    init(brews: [Brew]) {
        entries = brews.prefix(Brew.maximumCompared).enumerated().map { Entry(brew: $1, index: $0) }
    }

    var longestTime: TimeInterval { entries.map(\.totalTime).max() ?? 0 }
    var mostWater: Double { entries.flatMap(\.curve).map(\.milliliters).max() ?? 0 }

    var rows: [Row] {
        func row(_ title: String, _ value: (Entry) -> String) -> Row {
            Row(title: title, values: entries.map(value))
        }
        return [
            row(tr("Dose")) { gramsText($0.brew.doseGrams) },
            row(tr("Ratio")) { ratioText($0.brew.ratio) },
            row(tr("Water")) { millilitersText($0.brew.waterGrams.rounded()) },
            row(tr("Temperature")) { $0.brew.waterTemperature.map(celsiusText) ?? "—" },
            row(tr("Method")) { $0.brew.method.rawValue },
            row(tr("Brewer")) { $0.brew.device ?? "—" },
            row(tr("Clicks")) { $0.brew.grindSetting.map(String.init) ?? "—" },
            row(tr("Time")) { clockText($0.totalTime) },
            row(tr("First pour")) { $0.steps.pours.first.map(millilitersText) ?? "—" },
        ]
    }
}
