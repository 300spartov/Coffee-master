import SwiftUI
import Observation
import DesignSystem

/// The flavor wheel (web: `flavor-wheel`): Flavor / Aroma tabs, search, the wheel (categories →
/// groups → notes), and the picks as chips. Picks are saved as Ukrainian names, like the web app.
public struct FlavorWheelView: View {
    @Binding private var flavors: [String]
    @Binding private var aromas: [String]
    @State private var model: FlavorWheelModel

    public init(flavors: Binding<[String]>, aromas: Binding<[String]>) {
        _flavors = flavors
        _aromas = aromas
        _model = State(initialValue: FlavorWheelModel(flavors: flavors.wrappedValue, aromas: aromas.wrappedValue))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Picker(tr("Notes"), selection: $model.tab) {
                Text(tr("Flavor")).tag(FlavorWheelModel.Tab.flavor)
                Text(tr("Aroma")).tag(FlavorWheelModel.Tab.aroma)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("wheel.tab")

            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass").foregroundStyle(.theme.textTertiary)
                TextField(tr("Search notes"), text: $model.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("wheel.search")
            }
            .padding(Spacing.sm)
            .background(.theme.fill, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))

            FlavorWheelCanvas(
                layout: model.layout,
                hubTitle: model.selection.count > 0 ? "\(model.selection.count)" : "☕",
                hubSubtitle: model.selection.count > 0 ? tr("picked") : tr("pick a category"),
                perform: model.perform
            )
            .animation(.smooth(duration: 0.25), value: model.position)

            Text(model.hint).appTextStyle(.caption).frame(maxWidth: .infinity)

            if model.selection.count > 0 {
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(model.selection.sorted, id: \.self) { path in
                        PickChip(path: path) { model.selection.remove(path) }
                    }
                }
                Button(tr("Reset"), role: .destructive) { model.reset() }
                    .font(.footnote)
                    .accessibilityIdentifier("wheel.reset")
            }
        }
        .onChange(of: model.flavors.labels) { _, labels in flavors = labels }
        .onChange(of: model.aromas.labels) { _, labels in aromas = labels }
    }
}

/// "Fruit › Tropical › Mango ×".
private struct PickChip: View {
    let path: FlavorPath
    let remove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle().fill(Color(hex: path.category?.color ?? 0x888888)).frame(width: 8, height: 8)
            Text(verbatim: path.localizedParts.joined(separator: " › "))
                .font(.caption.weight(.medium))
                .foregroundStyle(.theme.textPrimary)
            Button(action: remove) {
                Image(systemName: "xmark").font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.theme.textSecondary)
            .accessibilityLabel(tr("Remove"))
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.theme.fill, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("wheel.pick.\(path.storedLabel)")
    }
}

/// The wheel's state: two selections (flavor, aroma), where the wheel is, and the search.
@Observable
final class FlavorWheelModel {
    enum Tab: Hashable { case flavor, aroma }

    var tab: Tab = .flavor {
        didSet { position = WheelPosition(); query = "" }
    }
    var flavors: FlavorSelection
    var aromas: FlavorSelection
    private(set) var position = WheelPosition()
    var query = ""

    init(flavors: [String], aromas: [String]) {
        self.flavors = FlavorSelection(labels: flavors)
        self.aromas = FlavorSelection(labels: aromas)
    }

    /// The current tab's picks.
    var selection: FlavorSelection {
        get { tab == .flavor ? flavors : aromas }
        set { if tab == .flavor { flavors = newValue } else { aromas = newValue } }
    }

    var layout: WheelLayout {
        WheelLayout(position: position, selection: selection, search: FlavorSearch(query))
    }

    var hint: String {
        if position.categoryID == nil { return tr("Tap a category — or search") }
        if position.groupID == nil { return tr("Pick a group, or tap the center to go back") }
        return tr("Tap the notes you taste")
    }

    func perform(_ action: WheelAction) {
        switch action {
        case .go(let target):
            position = target
        case .pick(let path):
            selection.pick(path)
            guard path.level < 3, let category = path.category else { return }
            // A category with one group goes straight to its notes, like the web app.
            let group = path.groupID ?? (category.groups.count == 1 ? category.groups[0].id : nil)
            if let group, path.level == 1 { selection.pick(FlavorPath(category: category.id, group: group)) }
            position = WheelPosition(category: category.id, group: group)
        }
    }

    func reset() {
        selection.reset()
        position = WheelPosition()
    }
}

#Preview {
    @Previewable @State var flavors = ["Манго", "Ваніль"]
    @Previewable @State var aromas: [String] = []
    ScrollView {
        FlavorWheelView(flavors: $flavors, aromas: $aromas).padding()
    }
}
