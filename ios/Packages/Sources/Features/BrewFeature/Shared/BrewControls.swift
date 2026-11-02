import SwiftUI
import Domain
import AppCore
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
            LinkLabel {
                GearRowLabel(
                    title: picked?.title ?? kind.prompt(for: model.method),
                    subtitle: picked == nil ? tr("Tap to choose") : picked?.subtitle,
                    kind: kind,
                    dripperKind: picked?.dripperKind,
                    stock: picked?.stock,
                    isPlaceholder: picked == nil
                )
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

/// Pour / Pause: large, filled in `tint` while active. Compact (stir / swirl / shake): smaller, with a
/// soft highlight while running. Both with an optional progress ring around the icon.
struct BigButton: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    let tint: Color
    let isActive: Bool
    var progress: Double = 0
    var isCompact = false
    let action: () -> Void

    var body: some View {
        let filled = isActive && !isCompact
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ProgressRing(progress: progress, color: filled ? .white : tint, track: tint.opacity(0.2)) {
                    Image(systemName: systemImage).font(isCompact ? .body.weight(.semibold) : .title3)
                }
                .frame(width: isCompact ? 36 : 44, height: isCompact ? 36 : 44)
                Text(title).font(isCompact ? .caption.weight(.semibold) : .headline).lineLimit(1).minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle).font(.caption).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .foregroundStyle(filled ? Color.white : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompact ? Spacing.md : Spacing.lg)
            .background(
                filled ? tint : tint.opacity(isActive ? 0.25 : (isCompact ? 0.1 : 0.12)),
                in: RoundedRectangle(cornerRadius: isCompact ? Radius.medium : Radius.large, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

extension AlertingViewModel {
    /// Saves a brew just made (taking its dose and a filter from stock) and hands it to the router; a
    /// failure becomes the alert. Returns whether it worked.
    func record(_ brew: Brew, in brews: any BrewRepository, then router: (any BrewSavingRouting)?) async -> Bool {
        await attempt {
            let usage = try await brews.record(brew)
            router?.brewDidSave(brew, usage: usage)
        }
    }
}

extension View {
    /// "Discard this brew?" for Back on a started brew (the timer, the rating).
    func discardBrewConfirmation(isPresented: Binding<Bool>, onDiscard: @escaping () -> Void) -> some View {
        confirmationDialog(tr("Discard this brew?"), isPresented: isPresented, titleVisibility: .visible) {
            Button(tr("Discard"), role: .destructive, action: onDiscard)
        }
    }
}

public extension StockUsage {
    /// Warnings after a brew took its coffee and filter: the bag used up or running low, filters low.
    var warnings: [String] {
        var warnings: [String] = []
        if let bean, bean.isLow {
            let name = bean.name
            warnings.append(bean.isEmpty ? tr("\(name) is used up") : tr("\(name) is running low"))
        }
        if let pack = filterPack, pack.isLow {
            let (name, left) = (pack.name, pack.remaining)
            warnings.append(pack.isEmpty ? tr("No filters left in \(name)") : tr("Only \(left) filters left in \(name)"))
        }
        return warnings
    }
}
