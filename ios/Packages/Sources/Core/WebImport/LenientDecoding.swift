import Foundation

/// A number that may arrive as a JSON number or a string with units ("16.0", "93°C", "28с", "1,5").
struct LenientNumber: Decodable, Hashable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self), let parsed = Self.parse(string) {
            value = parsed
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a number")
        }
    }

    var int: Int { Int(value.rounded()) }

    /// Extracts the leading number from strings like "93°C", "-1.5 g", "28с".
    static func parse(_ string: String) -> Double? {
        let normalized = string.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        var number = ""
        for character in normalized {
            if character.isNumber || character == "." || (character == "-" && number.isEmpty) {
                number.append(character)
            } else if !number.isEmpty {
                break
            }
        }
        return Double(number)
    }
}

/// Decodes an array, dropping elements that fail to decode.
struct LossyArray<Element: Decodable>: Decodable {
    var elements: [Element]

    init(_ elements: [Element] = []) {
        self.elements = elements
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                elements.append(element)
            } else {
                _ = try? container.decode(Skip.self)
            }
        }
        self.elements = elements
    }

    private struct Skip: Decodable {}
}

extension KeyedDecodingContainer {
    func lossyArray<T: Decodable>(forKey key: Key) -> LossyArray<T> {
        (try? decodeIfPresent(LossyArray<T>.self, forKey: key)) ?? LossyArray()
    }

    func lossyStrings(forKey key: Key) -> [String]? {
        (try? decodeIfPresent(LossyArray<String>.self, forKey: key))?.elements
    }

    func lenient(_ key: Key) -> LenientNumber? {
        (try? decodeIfPresent(LenientNumber.self, forKey: key)) ?? nil
    }

    func string(_ key: Key) -> String? {
        (try? decodeIfPresent(String.self, forKey: key)) ?? nil
    }
}

/// Optional field that decodes to `nil` instead of throwing when the value has an unexpected type.
@propertyWrapper
struct Lenient<Value: Decodable>: Decodable {
    var wrappedValue: Value?

    init(wrappedValue: Value?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        wrappedValue = try? Value(from: decoder)
    }
}

extension KeyedDecodingContainer {
    // Called by synthesized `init(from:)` for `@Lenient` properties; tolerates missing keys and bad values.
    func decode<Value>(_ type: Lenient<Value>.Type, forKey key: Key) throws -> Lenient<Value> {
        Lenient(wrappedValue: (try? decodeIfPresent(Value.self, forKey: key)) ?? nil)
    }
}
