import SwiftUI
import Domain
import DesignSystem
import BrewKit
import FlavorWheel

// The tabs under a brew card's "Details".

/// Recipe: what the card doesn't show (water, temperature), the gear, and milk / ice.
struct BrewRecipeDetails: View {
    let brew: Brew

    var body: some View {
        let rows = rows
        if rows.isEmpty {
            Text(tr("No recipe logged")).appTextStyle(.secondary)
        } else {
            DetailRows(rows: rows)
        }
    }

    private var rows: [DetailRows.Row] {
        var rows: [DetailRows.Row] = []
        if !brew.isCafeVisit {
            rows.append((tr("Volume"), millilitersText(brew.volumeMilliliters)))
            if let temperature = brew.waterTemperature { rows.append((tr("Temperature"), celsiusText(temperature))) }
        }
        if let dripper = brew.dripper { rows.append((tr("Brewer"), dripper.name)) }
        if let filter = brew.filter {
            rows.append((tr("Filter"), joined(filter.name, brew.isFilterRinsed.map { $0 ? tr("wet") : tr("dry") })))
        }
        if let machine = brew.espressoMachine { rows.append((tr("Machine"), machine.name)) }
        if let grinder = brew.grinder {
            rows.append((tr("Grinder"), joined(grinder.name, brew.grindSetting.map { tr("\($0) clicks") })))
        }
        if let milk = brew.milk {
            rows.append((tr("Milk"), joined(milk.name, milk.volumeMilliliters.map(millilitersText), milk.temperature.map(celsiusText), milk.frother)))
        }
        if let ice = brew.ice {
            rows.append((tr("Ice & mixer"), joined(ice.cubes.map { tr("\(Int($0)) cubes") }, ice.mixer)))
        }
        return rows.filter { !$0.value.isEmpty }
    }
}

/// Steps: the timer's log, or the shot for an espresso.
struct BrewStepsDetails: View {
    let brew: Brew

    var body: some View {
        if !brew.steps.isEmpty {
            BrewStepList(brew.steps)
        } else if let shot = brew.espresso {
            DetailRows(rows: shotRows(shot))
        } else {
            Text(tr("No steps logged")).appTextStyle(.secondary)
        }
    }

    private func shotRows(_ shot: EspressoShot) -> [DetailRows.Row] {
        let pressure = shot.pressureBar.map { "\(decimal($0)) \(tr("bar"))" }
        let rows: [DetailRows.Row] = [
            (tr("Shot time"), clockText(shot.shotTime)),
            (tr("Yield"), gramsText(shot.yieldGrams)),
            (tr("Pressure"), pressure ?? ""),
            (tr("Actual TDS"), shot.actualTDS.map { "\(decimal($0)) %" } ?? ""),
            (tr("Target TDS"), shot.targetTDS.map { "\(decimal($0)) %" } ?? ""),
        ]
        return rows.filter { !$0.value.isEmpty }
    }
}

/// Notes: flavors and aromas from the wheel, and what was written.
struct BrewNotesDetails: View {
    let brew: Brew

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            tags(tr("Flavor"), brew.flavors)
            tags(tr("Aroma"), brew.aromas)
            if !brew.notes.isEmpty {
                Text(verbatim: brew.notes)
                    .foregroundStyle(.theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(.theme.fill, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            }
        }
    }

    private func tags(_ title: String, _ labels: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).appTextStyle(.caption)
            if labels.isEmpty {
                Text(tr("Not set")).appTextStyle(.secondary)
            } else {
                FlavorTags(labels)
            }
        }
    }
}

/// "Grinder   Comandante · 24 clicks" rows.
private struct DetailRows: View {
    typealias Row = (title: String, value: String)

    let rows: [Row]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(rows, id: \.title) { row in
                LabeledContent(row.title, value: row.value).font(.subheadline)
            }
        }
    }
}

/// "Comandante · 24 clicks": the parts that are there.
private func joined(_ parts: String?...) -> String {
    parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
}
