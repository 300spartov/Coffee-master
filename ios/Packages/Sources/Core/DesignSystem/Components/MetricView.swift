import SwiftUI

/// A number with its unit and label: "16 g · Dose", "1:16 · Ratio", "3:05 · Time".
public struct MetricView: View {
    public enum Size: Sendable {
        case regular
        case large
    }

    private let value: String
    private let unit: String?
    private let label: String
    private let size: Size

    public init(value: String, unit: String? = nil, label: String, size: Size = .regular) {
        self.value = value
        self.unit = unit
        self.label = label
        self.size = size
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Text(value).appTextStyle(size == .large ? .metricLarge : .metric)
                if let unit {
                    Text(unit).appTextStyle(.caption)
                }
            }
            Text(label).appTextStyle(.caption)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack(spacing: Spacing.xl) {
        MetricView(value: "16", unit: "g", label: "Dose")
        MetricView(value: "1:16", label: "Ratio")
        MetricView(value: "3:05", label: "Time", size: .large)
    }
    .padding()
}
