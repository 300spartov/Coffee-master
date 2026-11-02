import SwiftUI
import Domain
import DesignSystem

public extension BrewStep {
    /// "Pour", "Pause", "Stir", …
    var title: String {
        switch kind {
        case .pour: tr("Pour")
        case .pause: tr("Pause")
        case .action(let action): action.title
        }
    }

    /// "0:10–0:45".
    var rangeText: String { "\(clockText(start))–\(clockText(end))" }

    var tint: Color {
        switch kind {
        case .pour: .theme.info
        case .pause: .theme.textSecondary
        case .action: .theme.success
        }
    }
}

/// A logged step: what, when (mm:ss–mm:ss), how long, and a pour's ml. Pass `milliliters` to make the
/// pour editable (the brew timer); otherwise the ml is shown (the journal).
public struct BrewStepRow: View {
    private let step: BrewStep
    private let milliliters: Binding<Double>?

    public init(step: BrewStep, milliliters: Binding<Double>? = nil) {
        self.step = step
        self.milliliters = milliliters
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(step.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(step.tint)
                .frame(width: 96, alignment: .leading)
            Text(verbatim: step.rangeText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.theme.textPrimary)
            Text(secondsText(step.duration))
                .font(.caption)
                .foregroundStyle(.theme.textSecondary)
            Spacer()
            if let milliliters {
                TextField(String("0"), value: milliliters, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .frame(width: 56)
            } else if let poured = step.pourMilliliters {
                Text(verbatim: decimal(poured)).font(.caption.weight(.semibold).monospacedDigit())
            }
            if step.isPour {
                Text(tr("ml")).font(.caption).foregroundStyle(.theme.textSecondary)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

/// Steps one under another, with dividers.
public struct BrewStepList: View {
    private let steps: [BrewStep]
    private let milliliters: ((Int) -> Binding<Double>?)?

    /// `milliliters`: an editable amount for the pour at an index (nil: read-only).
    public init(_ steps: [BrewStep], milliliters: ((Int) -> Binding<Double>?)? = nil) {
        self.steps = steps
        self.milliliters = milliliters
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                BrewStepRow(step: step, milliliters: milliliters?(index))
                if index < steps.count - 1 { Divider() }
            }
        }
    }
}
