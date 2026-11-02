import SwiftUI

/// An icon and a short text, tight together (a `Label` spaces them wide at small sizes): a brew's
/// method, a café, a city. Takes the font and color from its context. The text is data, so verbatim.
public struct CompactLabel: View {
    private let title: String
    private let systemImage: String

    public init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
            Image(systemName: systemImage)
            Text(verbatim: title).lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}
