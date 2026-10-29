/// A string-backed value with well-known presets but open to any value (methods, processes, actions).
///
/// `Codable` comes from the standard library's `RawRepresentable` support: it encodes as a plain
/// string and decodes through `init(rawValue:)`. String literals work too: `let method: BrewMethod = "V60"`.
public protocol StringBacked: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral
where RawValue == String {
    init(rawValue: String)
}

public extension StringBacked {
    init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
