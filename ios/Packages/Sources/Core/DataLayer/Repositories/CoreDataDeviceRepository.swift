import Foundation
import Domain

public struct CoreDataDeviceRepository: DeviceRepository {
    private let store: RecordStore<Device>

    public init(persistence: PersistenceController) {
        store = RecordStore(persistence: persistence)
    }

    public func fetchAll() async throws -> [Device] { try await store.fetchAll() }

    public func fetchAll(of type: DeviceType) async throws -> [Device] {
        let rawType = type.rawValue
        return try await store.fetchAll { NSPredicate(format: "%K == %@", CoreDataModel.Attribute.type, rawType) }
    }

    public func contains(name: String, type: DeviceType) async throws -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await fetchAll(of: type).contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    public func fetch(id: Device.ID) async throws -> Device {
        guard let device = try await store.fetch(id: id) else { throw RepositoryError.notFound }
        return device
    }

    public func save(_ device: Device) async throws {
        var device = device
        device.touch()
        try await store.upsert([device], policy: .overwrite)
    }

    public func delete(id: Device.ID) async throws { try await store.softDelete(id: id) }

    public func changes() async -> AsyncStream<Void> { store.changes() }
}
