import SwiftUI
import Domain
import BrewKit
import DesignSystem

// Controls shared by the brew wizard's screens (pour-over and espresso).

/// A setup screen's view model that picks gear (pour-over and espresso).
protocol GearPickingModel: AnyObject {
    var method: BrewMethod { get }
    var gearPresenter: (any GearPickerPresenting)? { get }
    /// The picked item for a row, as the picker shows it.
    func picked(_ kind: GearKind) -> GearPickerViewModel.Row?
    func apply(_ pick: GearPick)
}

extension GearPickingModel {
    /// Opens the picker for `kind`; the pick comes back through `apply`.
    func choose(_ kind: GearKind) {
        gearPresenter?.showGearPicker(kind, method: method, selectedID: picked(kind)?.ownedID) { [weak self] pick in
            self?.apply(pick)
        }
    }
}

/// A setup row: the picked item, or the "Choose …" prompt; tapping opens the picker.
struct GearRowButton: View {
    let kind: GearKind
    let model: any GearPickingModel

    var body: some View {
        let picked = model.picked(kind)
        Button {
            model.choose(kind)
        } label: {
            HStack {
                GearRowLabel(
                    title: picked?.title ?? kind.prompt(for: model.method),
                    subtitle: picked == nil ? tr("Tap to choose") : picked?.subtitle,
                    kind: kind,
                    dripperKind: picked?.dripperKind,
                    stock: picked?.stock,
                    isPlaceholder: picked == nil
                )
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.theme.textTertiary)
            }
        }
        .accessibilityIdentifier("setup.\(kind.rawValue)")
    }
}

/// A value on a slider with − / +: temperature, pressure.
struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Stepper(value: $value, in: range, step: step) {
                LabeledContent(title, value: "\(decimal(value)) \(unit)")
            }
            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(title)
        }
    }
}

/// Calls `refresh` a few times a second until the task is cancelled (bind it to a screen with `.task`):
/// the brew clocks, which keep timestamps and only need redrawing.
func refreshWhileVisible(_ refresh: () -> Void) async {
    while !Task.isCancelled {
        refresh()
        try? await Task.sleep(for: .milliseconds(200))
    }
}

/// A thick progress bar in `color`, with optional marks (0...1).
struct ProgressBar: View {
    let fraction: Double
    let color: Color
    var marks: [Double] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.theme.fill)
                Capsule().fill(color).frame(width: proxy.size.width * min(max(fraction, 0), 1))
                ForEach(marks, id: \.self) { mark in
                    Rectangle()
                        .fill(mark <= fraction ? Color.theme.textTertiary : color.opacity(0.6))
                        .frame(width: 2)
                        .offset(x: proxy.size.width * mark)
                }
            }
        }
        .frame(height: 10)
        .animation(.smooth, value: fraction)
        .accessibilityHidden(true)
    }
}

/// Pour / Pause: large, with an optional progress ring around the icon.
struct BigButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isActive: Bool
    var progress: Double = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ProgressRing(progress: progress, tint: tint, ringColor: isActive ? .white : tint) {
                    Image(systemName: systemImage).font(.title3)
                }
                .frame(width: 44, height: 44)
                Text(title).font(.headline)
                Text(subtitle).font(.caption).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(isActive ? Color.white : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(isActive ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// An icon inside a ring that fills clockwise with `progress` (0...1).
struct ProgressRing<Content: View>: View {
    let progress: Double
    let tint: Color
    /// The filled part (default: `tint`).
    var ringColor: Color?
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.2), lineWidth: 3)
            Circle().trim(from: 0, to: progress).stroke(ringColor ?? tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            content
        }
    }
}
