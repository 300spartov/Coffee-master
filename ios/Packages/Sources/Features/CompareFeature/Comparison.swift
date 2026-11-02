import Foundation
import Domain
import BrewKit

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

    /// The web's limit.
    static let maximumBrews = 4

    let entries: [Entry]

    init(brews: [Brew]) {
        entries = brews.prefix(Self.maximumBrews).enumerated().map { Entry(brew: $1, index: $0) }
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
