import SwiftUI
import AppCore

/// Text field that offers earlier values (roasters, bean names, milks, mixers) while it's focused, as
/// tappable chips in the bar above the keyboard (`keyboardBar`). Uses the system keyboard.
public struct AutocompleteField: View {
    private let title: String
    @Binding private var text: String
    private let suggestions: [String]
    @FocusState private var isFocused: Bool
    @State private var id = UUID()
    /// Missing outside a screen root (e.g. a bare preview): no suggestions then.
    @Environment(KeyboardSuggestions.self) private var keyboard: KeyboardSuggestions?

    public init(_ title: String, text: Binding<String>, suggestions: [String]) {
        self.title = title
        _text = text
        self.suggestions = suggestions
    }

    public var body: some View {
        TextField(title, text: $text)
            .focused($isFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onChange(of: isFocused) { updateKeyboard() }
            .onChange(of: text) { updateKeyboard() }
            .onChange(of: suggestions) { updateKeyboard() }
            .onDisappear { keyboard?.clear(owner: id) }
    }

    private func updateKeyboard() {
        guard let keyboard else { return }
        if isFocused {
            keyboard.show(Autocomplete.matches(for: text, in: suggestions), owner: id) { text = $0 }
        } else {
            keyboard.clear(owner: id)
        }
    }
}

/// Picks the suggestions to show for what's typed so far.
public nonisolated enum Autocomplete {
    /// Case- and diacritic-insensitive. Prefix matches come first, then other matches; values equal to
    /// the query are left out (nothing to complete). With an empty query, the first `limit` values.
    public static func matches(for query: String, in candidates: [String], limit: Int = 6) -> [String] {
        let query = query.trimmed
        var seen = Set<String>()
        let unique = candidates.filter { candidate in
            let key = candidate.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            return !candidate.trimmingCharacters(in: .whitespaces).isEmpty && seen.insert(key).inserted
        }
        guard !query.isEmpty else { return Array(unique.prefix(limit)) }

        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let others = unique.filter { $0.compare(query, options: options) != .orderedSame }
        let prefix = others.filter { $0.range(of: query, options: options.union(.anchored)) != nil }
        let contains = others.filter { !prefix.contains($0) && $0.range(of: query, options: options) != nil }
        return Array((prefix + contains).prefix(limit))
    }
}

#Preview {
    @Previewable @State var roaster = "Pe"
    Form {
        AutocompleteField("Roaster", text: $roaster, suggestions: ["Penyora", "Wonder&Full", "Mad Heads"])
    }
    .keyboardBar()
}
