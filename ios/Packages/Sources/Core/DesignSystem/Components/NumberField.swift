import SwiftUI

/// Labeled numeric input with a unit, using the system decimal keyboard.
/// The value is clamped to `range` when editing ends.
public struct NumberField: View {
    private let title: String
    @Binding private var value: Double
    private let unit: String?
    private let range: ClosedRange<Double>
    private let fractionDigits: Int
    @FocusState private var isFocused: Bool

    public init(
        _ title: String,
        value: Binding<Double>,
        unit: String? = nil,
        range: ClosedRange<Double> = 0...10_000,
        fractionDigits: Int = 1
    ) {
        self.title = title
        _value = value
        self.unit = unit
        self.range = range
        self.fractionDigits = fractionDigits
    }

    public var body: some View {
        LabeledContent {
            HStack(spacing: Spacing.xs) {
                TextField(title, value: $value, format: .number.precision(.fractionLength(0...fractionDigits)))
                    .keyboardType(fractionDigits > 0 ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .focused($isFocused)
                    .frame(minWidth: 60)
                if let unit {
                    Text(unit).foregroundStyle(.theme.textSecondary)
                }
            }
        } label: {
            Text(title).foregroundStyle(.theme.textPrimary)
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { value = Self.clamp(value, to: range) }
        }
    }

    nonisolated static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

#Preview {
    @Previewable @State var dose = 16.0
    @Previewable @State var temperature = 93.0
    Form {
        NumberField("Dose", value: $dose, unit: "g", range: 1...60)
        NumberField("Temperature", value: $temperature, unit: "°C", range: 70...100, fractionDigits: 0)
    }
}
