import SwiftUI
import AppCore

/// Labeled numeric input with a unit, using the system decimal keyboard.
/// The value is clamped to `range` when editing ends. With `step`, a − / + stepper sits beside it.
/// Optional values can be left empty (`placeholder` shows then).
public struct NumberField: View {
    private let title: String
    @Binding private var value: Double?
    private let unit: String?
    private let placeholder: String?
    private let range: ClosedRange<Double>
    private let fractionDigits: Int
    private let step: Double?
    @FocusState private var isFocused: Bool

    /// An optional value; empty shows `placeholder`. No stepper (it needs a value).
    public init(
        _ title: String,
        value: Binding<Double?>,
        unit: String? = nil,
        placeholder: String? = nil,
        range: ClosedRange<Double> = 0...10_000,
        fractionDigits: Int = 1
    ) {
        self.title = title
        _value = value
        self.unit = unit
        self.placeholder = placeholder
        self.range = range
        self.fractionDigits = fractionDigits
        step = nil
    }

    public init(
        _ title: String,
        value: Binding<Double>,
        unit: String? = nil,
        range: ClosedRange<Double> = 0...10_000,
        fractionDigits: Int = 1,
        step: Double? = nil
    ) {
        self.title = title
        // While the text is cleared mid-edit, keep the last value.
        _value = Binding(get: { value.wrappedValue }, set: { if let new = $0 { value.wrappedValue = new } })
        self.unit = unit
        placeholder = nil
        self.range = range
        self.fractionDigits = fractionDigits
        self.step = step
    }

    /// Whole numbers (grinder clicks, …).
    public init(_ title: String, value: Binding<Int>, unit: String? = nil, range: ClosedRange<Int>, step: Int? = nil) {
        self.init(
            title,
            value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0.rounded()) }),
            unit: unit,
            range: Double(range.lowerBound)...Double(range.upperBound),
            fractionDigits: 0,
            step: step.map(Double.init)
        )
    }

    public var body: some View {
        LabeledContent {
            HStack(spacing: Spacing.xs) {
                TextField(placeholder ?? title, value: $value, format: .number.precision(.fractionLength(0...fractionDigits)))
                    .keyboardType(fractionDigits > 0 ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .focused($isFocused)
                    .frame(minWidth: 60)
                if let unit {
                    Text(unit).foregroundStyle(.theme.textSecondary)
                }
                if let step {
                    Stepper(title, value: Binding(get: { value ?? range.lowerBound }, set: { value = $0 }), in: range, step: step)
                        .labelsHidden()
                }
            }
        } label: {
            Text(title).foregroundStyle(.theme.textPrimary)
        }
        .onChange(of: isFocused) { _, focused in
            if !focused, let current = value { value = current.clamped(to: range) }
        }
    }
}

#Preview {
    @Previewable @State var dose = 16.0
    @Previewable @State var clicks = 28
    @Previewable @State var yield: Double?
    Form {
        NumberField("Dose", value: $dose, unit: "g", range: 1...60)
        NumberField("Clicks", value: $clicks, range: 1...200, step: 1)
        NumberField("Yield", value: $yield, unit: "g", placeholder: "36")
    }
}
