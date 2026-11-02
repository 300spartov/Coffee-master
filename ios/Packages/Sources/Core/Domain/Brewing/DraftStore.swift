import Foundation

/// Small key-value storage for work in progress (the brew being made), so an app kill doesn't lose it.
public protocol DraftStore: Sendable {
    func data(for key: String) -> Data?
    /// `nil` removes the draft.
    func setData(_ data: Data?, for key: String)
}

public extension DraftStore {
    /// The draft under `key`, or nil if there's none or it can't be read (a draft is a convenience).
    func load<Draft: Decodable>(_ type: Draft.Type, key: String) -> Draft? {
        data(for: key).flatMap { try? JSONDecoder().decode(Draft.self, from: $0) }
    }

    func save(_ draft: some Encodable, key: String) {
        setData(try? JSONEncoder().encode(draft), for: key)
    }

    func remove(_ key: String) {
        setData(nil, for: key)
    }
}
