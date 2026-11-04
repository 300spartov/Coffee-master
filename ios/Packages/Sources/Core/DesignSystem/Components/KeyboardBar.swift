import SwiftUI
import UIKit

public extension View {
    /// The bar above the keyboard: the focused `AutocompleteField`'s suggestions (the system's own
    /// suggestion row can't take an app's words) and Done, so the keyboard can always be closed by hand
    /// (number pads have no return key). Applied once at each screen's root (`LocalizedRoot`).
    func keyboardBar() -> some View {
        modifier(KeyboardBar())
    }
}

/// What the focused field offers in the keyboard bar. Fields take it over while focused (`owner`), so
/// one losing focus after another gained it doesn't clear the newer list.
@Observable
final class KeyboardSuggestions {
    private(set) var items: [String] = []
    @ObservationIgnored private var owner: UUID?
    @ObservationIgnored private var pick: ((String) -> Void)?

    func show(_ items: [String], owner: UUID, pick: @escaping (String) -> Void) {
        self.owner = owner
        self.pick = pick
        if self.items != items { self.items = items }
    }

    func clear(owner: UUID) {
        guard self.owner == owner else { return }
        self.owner = nil
        pick = nil
        items = []
    }

    func select(_ item: String) {
        pick?(item)
    }
}

private struct KeyboardBar: ViewModifier {
    @State private var suggestions = KeyboardSuggestions()

    func body(content: Content) -> some View {
        content
            .environment(suggestions)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if suggestions.items.isEmpty {
                        Spacer()   // Done alone, on the right
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(suggestions.items, id: \.self) { item in
                                    Chip(item) { suggestions.select(item) }
                                        .accessibilityIdentifier("keyboard.suggestion")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    Button(tr("Done")) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("keyboard.done")
                }
            }
    }
}
