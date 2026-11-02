import SwiftUI
import Charts
import Domain
import DesignSystem
import BrewKit

struct CompareView: View {
    @Bindable var viewModel: CompareViewModel

    private var comparison: Comparison { viewModel.comparison }

    var body: some View {
        LoadStateView(viewModel.state) {
            Task { await viewModel.load() }
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Picker(tr("Chart"), selection: $viewModel.chart) {
                        Text(tr("Timeline")).tag(CompareViewModel.Chart.timeline)
                        Text(tr("Rings")).tag(CompareViewModel.Chart.rings)
                        Text(tr("Curve")).tag(CompareViewModel.Chart.curve)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("compare.chart")

                    switch viewModel.chart {
                    case .timeline: timeline
                    case .rings: rings
                    case .curve: curve
                    }
                }
                .padding(Spacing.lg)
                .animation(.smooth(duration: 0.2), value: viewModel.highlighted)
            }
        }
        .themedGroupedBackground()
        .task { await viewModel.load() }
        .accessibilityIdentifier("compare")
    }

    // MARK: - Timeline

    private var timeline: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Picker(tr("Unit"), selection: $viewModel.unit) {
                Text(tr("Seconds")).tag(CompareViewModel.Unit.seconds)
                Text(tr("Milliliters")).tag(CompareViewModel.Unit.milliliters)
            }
            .pickerStyle(.segmented)
            ForEach(comparison.entries) { entry in
                TimelineCard(entry: entry, unit: viewModel.unit)
                    .opacity(viewModel.isFaded(entry) ? 0.35 : 1)
            }
            ParametersTable(comparison: comparison)
            Text(tr("Orange: differs from the others")).appTextStyle(.caption)
        }
    }

    // MARK: - Rings

    private var rings: some View {
        VStack(spacing: Spacing.md) {
            StepRings(comparison: comparison, isFaded: viewModel.isFaded)
                .frame(width: 280, height: 280)
                .frame(maxWidth: .infinity)
                .cardStyle()
            legend { entry in tr("Ring \(entry.index + 1)") }
        }
    }

    // MARK: - Curve

    private var curve: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Chart {
                ForEach(comparison.entries) { entry in
                    let color = Comparison.color(entry)
                    let opacity = viewModel.isFaded(entry) ? 0.2 : 1
                    ForEach(entry.curve, id: \.self) { point in
                        LineMark(x: .value(tr("Time"), point.seconds), y: .value(tr("Water"), point.milliliters), series: .value(tr("Brew"), entry.index))
                            .foregroundStyle(color.opacity(opacity))
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineJoin: .round))
                    }
                    ForEach(entry.actions, id: \.self) { point in
                        PointMark(x: .value(tr("Time"), point.seconds), y: .value(tr("Water"), point.milliliters))
                            .foregroundStyle(Color.theme.success.opacity(opacity))
                            .symbolSize(40)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel { if let seconds = value.as(Double.self) { Text(verbatim: clockText(seconds)) } }
                }
            }
            .chartYAxisLabel(tr("ml"))
            .frame(height: 240)
            .cardStyle()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("compare.curve")
            legend { entry in "\(millilitersText(entry.curve.last?.milliliters ?? 0)) · \(clockText(entry.totalTime))" }
            Text(tr("Flat: a pause · dot: an action · steepness: how fast you pour")).appTextStyle(.caption)
        }
    }

    /// The brews as tappable cards under a chart; tapping one highlights it.
    private func legend(_ detail: @escaping (Comparison.Entry) -> String) -> some View {
        ForEach(comparison.entries) { entry in
            Button {
                viewModel.toggleHighlight(entry)
            } label: {
                EntryHeader(entry: entry, detail: detail(entry))
                    .cardStyle(padding: Spacing.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                            .strokeBorder(viewModel.highlighted == entry.id ? Comparison.color(entry) : .clear, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .opacity(viewModel.isFaded(entry) ? 0.35 : 1)
            .accessibilityIdentifier("compare.entry")
        }
    }
}

// MARK: - Pieces

extension Comparison {
    /// The brews' colors in every chart (web: `CP_COLORS`).
    private static let palette = [ThemeColor(0xE8955C), ThemeColor(0x7FB08A), ThemeColor(0xC9A86A), ThemeColor(0x8198AE)].map(\.color)

    static func color(_ entry: Entry) -> Color {
        palette[entry.index % palette.count]
    }

    /// A step's color in the timeline and the rings: pours blue, pauses orange, actions green.
    static func color(_ step: BrewStep) -> Color {
        switch step.kind {
        case .pour: .theme.info
        case .pause: .theme.warning
        case .action: .theme.success
        }
    }
}

/// "● Kenya", "Oct 29 · 16 g · 3:05 · 93°", the rating.
private struct EntryHeader: View {
    let entry: Comparison.Entry
    let detail: String
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle().fill(Comparison.color(entry)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: entry.brew.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.theme.textPrimary)
                    .lineLimit(1)
                Text(verbatim: "\(entry.brew.date.formatted(.dateTime.day().month().locale(locale))) · \(detail)")
                    .appTextStyle(.caption)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.xs)
            Text(entry.brew.rating, format: .number.precision(.fractionLength(1)))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.rating(entry.brew.rating))
        }
    }
}

/// A brew's steps as one bar on its own clock; tap for the step list.
private struct TimelineCard: View {
    let entry: Comparison.Entry
    let unit: CompareViewModel.Unit
    @State private var showsSteps = false

    var body: some View {
        let total = max(entry.totalTime, 1)
        VStack(alignment: .leading, spacing: Spacing.sm) {
            EntryHeader(entry: entry, detail: detail)
            GeometryReader { proxy in
                HStack(spacing: 1) {
                    ForEach(Array(entry.steps.enumerated()), id: \.offset) { _, step in
                        let label = unit == .seconds ? "\(Int(step.duration.rounded()))" : step.pourMilliliters.map { "\(Int($0.rounded()))" } ?? ""
                        Comparison.color(step)
                            .opacity(unit == .milliliters && !step.isPour ? 0.5 : 1)
                            .overlay(Text(verbatim: label).font(.caption2.weight(.bold).monospacedDigit()).foregroundStyle(.white).minimumScaleFactor(0.5).lineLimit(1))
                            .frame(width: max(proxy.size.width * step.duration / total - 1, 1))
                    }
                }
            }
            .frame(height: 26)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            HStack {
                Text(verbatim: clockText(0))
                Spacer()
                Text(verbatim: clockText(entry.totalTime))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.theme.textTertiary)
            if showsSteps {
                BrewStepList(entry.steps)
            }
        }
        .cardStyle(padding: Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.smooth(duration: 0.2)) { showsSteps.toggle() } }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compare.timeline")
    }

    private var detail: String {
        let brew = entry.brew
        let temperature = brew.waterTemperature.map { "\(decimal($0))°" }
        return [gramsText(brew.doseGrams), clockText(entry.totalTime), temperature].compactMap { $0 }.joined(separator: " · ")
    }
}

/// The parameters, a column per brew; values found in no other brew are orange.
private struct ParametersTable: View {
    let comparison: Comparison
    @Environment(\.locale) private var locale

    var body: some View {
        Grid(alignment: .trailing, horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.sm) {
            GridRow {
                Text(tr("Parameters")).appTextStyle(.caption).gridColumnAlignment(.leading)
                ForEach(comparison.entries) { entry in
                    Text(verbatim: entry.brew.date.formatted(.dateTime.day().month(.twoDigits).locale(locale)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Comparison.color(entry))
                }
            }
            ForEach(comparison.rows) { row in
                GridRow {
                    Text(verbatim: row.title).foregroundStyle(.theme.textSecondary)
                    ForEach(Array(zip(row.values, row.differs).enumerated()), id: \.offset) { _, cell in
                        Text(verbatim: cell.0)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(cell.1 ? Color.theme.warning : Color.theme.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .minimumScaleFactor(0.7)
                    }
                }
                .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compare.parameters")
    }
}

/// A ring per brew (the first outside), its steps around it on its own clock; the longest time inside.
private struct StepRings: View {
    let comparison: Comparison
    let isFaded: (Comparison.Entry) -> Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let width = comparison.entries.count >= 4 ? 13.0 : 17.0
            let pitch = width + 5
            ZStack {
                ForEach(comparison.entries) { entry in
                    let diameter = side - width - Double(entry.index) * pitch * 2
                    let total = max(entry.totalTime, 1)
                    ZStack {
                        Circle().stroke(.theme.fill, lineWidth: width)
                        ForEach(Array(entry.steps.enumerated()), id: \.offset) { _, step in
                            Circle()
                                .trim(from: step.start / total, to: min(step.end / total, 1))
                                .stroke(Comparison.color(step), lineWidth: width)
                        }
                    }
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))
                    .opacity(isFaded(entry) ? 0.25 : 1)
                }
                VStack(spacing: 0) {
                    Text(verbatim: clockText(comparison.longestTime))
                        .font(.system(size: 26, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(.theme.textPrimary)
                    Text(tr("Time")).appTextStyle(.caption)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compare.rings")
    }
}

#if DEBUG
#Preview {
    CompareView(viewModel: CompareViewModel(brewIDs: Brew.samples.map(\.id)))
}
#endif
