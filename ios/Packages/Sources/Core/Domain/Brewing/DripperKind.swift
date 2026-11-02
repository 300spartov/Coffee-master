import Foundation

/// What kind of brewer a dripper is, guessed from its name like the web app's `dripperType`.
/// Drives which owned drippers a method offers and which drawing the brew screens show.
public enum DripperKind: String, Sendable, CaseIterable {
    /// Cone drippers (V60, Kalita, Kono, …) and anything unrecognized.
    case cone
    case origami
    case flower
    case aeropress
    case chemex
    case frenchPress
    case coldBrew
    case batch

    public init(deviceName: String) {
        let name = deviceName.lowercased()
        func has(_ keywords: String...) -> Bool { keywords.contains { name.contains($0) } }
        if has("origami") {
            self = .origami
        } else if has("flower") {
            self = .flower
        } else if has("aeropress", "aero") {
            self = .aeropress
        } else if has("chemex") {
            self = .chemex
        } else if has("french", "френч") {
            self = .frenchPress
        } else if has("cold", "колд", "toddy", "mizudashi", "filtron", "oxo") {
            self = .coldBrew
        } else if has("batch", "бетч", "бэтч", "moccamaster", "bonavita", "aiden") {
            self = .batch
        } else {
            self = .cone
        }
    }

    /// Kinds that belong to one method only; the other methods don't offer them.
    static let methodSpecific: Set<DripperKind> = [.aeropress, .chemex, .frenchPress, .coldBrew, .batch]

    /// The method this kind brews (cones and anything unrecognized: V60).
    public var method: BrewMethod {
        switch self {
        case .cone: .v60
        case .origami: .origami
        case .flower: .flower
        case .aeropress: .aeropress
        case .chemex: .chemex
        case .frenchPress: .frenchPress
        case .coldBrew: .coldBrew
        case .batch: .batchBrewing
        }
    }

    /// The one kind `method` needs (AeroPress → AeroPress), or `nil` when any cone-style dripper fits (V60, …).
    public static func required(for method: BrewMethod) -> DripperKind? {
        methodSpecific.first { $0.method == method }
    }

    /// Whether a dripper of this kind can be used for `method`.
    public func fits(_ method: BrewMethod) -> Bool {
        if let required = Self.required(for: method) { return self == required }
        return !Self.methodSpecific.contains(self)
    }

    /// Name shown under the dripper (the method's proper name, the same in every language).
    public var displayName: String { method.rawValue }
}
