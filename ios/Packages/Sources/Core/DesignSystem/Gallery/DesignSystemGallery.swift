import SwiftUI

/// Every design-system component and color role on one screen.
/// Reachable in Debug builds from Settings → Developer → Design System
/// (or `coffeemaster://settings/design-system`). Switch light/dark to review both themes.
public struct DesignSystemGallery: View {
    private let showToast: (Toast) -> Void

    public init(showToast: @escaping (Toast) -> Void) {
        self.showToast = showToast
    }

    public var body: some View {
        ScrollView {
            GalleryContent(showToast: showToast)
                .padding(Spacing.lg)
        }
        .themedGroupedBackground()
    }
}

/// The gallery sections without the scroll view (renderable with `ImageRenderer` for reviews).
struct GalleryContent: View {
    let showToast: (Toast) -> Void

    @State private var selectedFlavors: Set<String> = ["Jasmine", "Peach"]
    @State private var dose = 16.0
    @State private var temperature = 93.0
    @State private var period = "Week"
    @State private var rating = 8.5
    @State private var roaster = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            colors
            typography
            buttons
            cards
            chips
            indicators
            inputs
            states
            toasts
        }
    }

    // MARK: - Sections

    private var colors: some View {
        section("Colors") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Spacing.sm)], spacing: Spacing.sm) {
                ForEach(ColorPalette.roles, id: \.name) { role in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: Radius.small)
                            .fill(Color.theme[dynamicMember: role.keyPath])
                            .frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: Radius.small).strokeBorder(.theme.separator, lineWidth: 0.5))
                        Text(role.name).appTextStyle(.caption).lineLimit(1)
                    }
                }
            }
        }
    }

    private var typography: some View {
        section("Typography") {
            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("3:05").appTextStyle(.metricLarge)
                    Text("16.0 g").appTextStyle(.metric)
                    Text("Section title").appTextStyle(.sectionTitle)
                    Text("Card title").appTextStyle(.cardTitle)
                    Text("Body text for notes and descriptions.").appTextStyle(.body)
                    Text("Secondary · metadata").appTextStyle(.secondary)
                    Text("Caption").appTextStyle(.caption)
                }
            }
        }
    }

    private var buttons: some View {
        section("Buttons") {
            VStack(spacing: Spacing.md) {
                Button("Primary") {}.buttonStyle(.primary)
                Button("Secondary") {}.buttonStyle(.secondary)
                Button("Disabled") {}.buttonStyle(.primary).disabled(true)
                Button("Destructive", role: .destructive) {}
                    .foregroundStyle(.theme.error)
            }
        }
    }

    private var cards: some View {
        section("Cards & rows") {
            Card {
                HStack(spacing: Spacing.md) {
                    IconBadge("drop")
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Ethiopia Yirgacheffe").appTextStyle(.cardTitle)
                        Text("V60 · 1:16 · 93 °C").appTextStyle(.secondary)
                    }
                    Spacer()
                    RatingRing(rating: 9.2, size: 44)
                }
            }
            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Brazil Cerrado").appTextStyle(.cardTitle)
                        Spacer()
                        Text("160 / 250 g").appTextStyle(.secondary)
                    }
                    StockBar(fraction: 0.64)
                }
            }
            HStack(spacing: Spacing.md) {
                StatTile(title: "Brews", value: "85")
                StatTile(title: "Streak", value: "12 days")
            }
            SectionHeader("Section header", actionTitle: "Action") {}
        }
    }

    private var chips: some View {
        section("Chips") {
            ChipGroup(["Jasmine", "Bergamot", "Black tea", "Honey", "Peach", "Caramel", "Chocolate"], selection: $selectedFlavors)
            ChipGroup(["V60", "Washed", "Light roast"])
            HStack {
                Chip("Cold Brew", systemImage: "snowflake")
                Chip("Selected", systemImage: "checkmark", isSelected: true)
            }
        }
    }

    private var indicators: some View {
        section("Indicators") {
            Card {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(spacing: Spacing.xl) {
                        RatingRing(rating: rating, size: 64, lineWidth: 6)
                        RatingView(rating: rating)
                        Spacer()
                    }
                    Slider(value: $rating, in: 0...10, step: 0.5).tint(.theme.accent)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        StockBar(fraction: 0.8)
                        StockBar(fraction: 0.15)
                        StockBar(fraction: 0)
                    }
                    HStack(spacing: Spacing.xl) {
                        MetricView(value: "16", unit: "g", label: "Dose")
                        MetricView(value: "1:16", label: "Ratio")
                        MetricView(value: "3:05", label: "Time", size: .large)
                    }
                    HStack(spacing: Spacing.md) {
                        IconBadge("drop")
                        IconBadge("cup.and.saucer.fill", tint: .theme.info)
                        IconBadge("checkmark.seal.fill", tint: .theme.success)
                        IconBadge("exclamationmark.triangle.fill", tint: .theme.warning)
                        IconBadge("xmark.octagon.fill", tint: .theme.error)
                    }
                }
            }
        }
    }

    private var inputs: some View {
        section("Inputs (system keyboards)") {
            Card(padding: Spacing.md) {
                VStack(spacing: Spacing.md) {
                    NumberField("Dose", value: $dose, unit: "g", range: 1...60)
                    Divider()
                    NumberField("Temperature", value: $temperature, unit: "°C", range: 70...100, fractionDigits: 0)
                    Divider()
                    AutocompleteField("Roaster", text: $roaster, suggestions: ["Penyora", "Wonder&Full", "Mad Heads", "Svit Kavy"])
                    Divider()
                    Picker("Period", selection: $period) {
                        ForEach(["Week", "Month", "Year"], id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var states: some View {
        section("States") {
            Card {
                EmptyStateView(
                    title: "No beans yet",
                    systemImage: "leaf",
                    message: "Add the coffee you have at home.",
                    actionTitle: "Add Bean"
                ) {}
            }
        }
    }

    private var toasts: some View {
        section("Toasts") {
            VStack(spacing: Spacing.sm) {
                Button("Success") { showToast(Toast("Brew saved", style: .success)) }.buttonStyle(.secondary)
                Button("Warning") { showToast(Toast("Only 8 filters left", style: .warning)) }.buttonStyle(.secondary)
                Button("Error") { showToast(Toast("Import failed", style: .error)) }.buttonStyle(.secondary)
                Button("With action") {
                    showToast(Toast("Brew deleted", action: Toast.Action("Undo") { showToast(Toast("Restored", style: .success)) }))
                }
                .buttonStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title)
            content()
        }
    }
}

#Preview {
    DesignSystemGallery { _ in }
}
