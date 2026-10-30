import Foundation
import Domain

public struct TestError: LocalizedError, Equatable {
    public init() {}
    public var errorDescription: String? { "Boom" }
}

/// What a `TestRepository` fails with `TestError`.
public enum TestFailure: Sendable {
    case none
    /// Reads and writes.
    case everything
    /// Saves, deletes and stock changes; reads keep working.
    case writes
}

/// Repository for view model tests: the real in-memory one (same ordering, soft delete, change
/// stream), plus failure injection and a log of every record passed to `save`.
public actor TestRepository<Record: Syncable>: RecordRepository {
    public let base: InMemoryRecordRepository<Record>
    private let failing: TestFailure
    /// Records as passed to `save`, oldest first.
    public private(set) var saved: [Record] = []

    public init(_ base: InMemoryRecordRepository<Record>, failing: TestFailure = .none) {
        self.base = base
        self.failing = failing
    }

    public func fetchAll() async throws -> [Record] {
        try await read { try await base.fetchAll() }
    }

    public func fetch(id: UUID) async throws -> Record {
        try await read { try await base.fetch(id: id) }
    }

    public func save(_ record: Record) async throws {
        try await write {
            saved.append(record)
            try await base.save(record)
        }
    }

    public func delete(id: UUID) async throws {
        try await write { try await base.delete(id: id) }
    }

    public func changes() async -> AsyncStream<Void> {
        await base.changes()
    }

    func read<T>(_ body: () async throws -> T) async throws -> T {
        if failing == .everything { throw TestError() }
        return try await body()
    }

    func write<T>(_ body: () async throws -> T) async throws -> T {
        if failing != .none { throw TestError() }
        return try await body()
    }
}

extension TestRepository: BrewRepository where Record == Brew {
    public init(brews: [Brew] = [], failing: TestFailure = .none) {
        self.init(InMemoryRecordRepository(brews: brews), failing: failing)
    }
}

extension TestRepository: BeanRepository where Record == Bean {
    public init(beans: [Bean] = [], failing: TestFailure = .none) {
        self.init(InMemoryRecordRepository(beans: beans), failing: failing)
    }

    public func consume(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try await write { try await base.consume(beanID: beanID, grams: grams) }
    }

    public func restock(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try await write { try await base.restock(beanID: beanID, grams: grams) }
    }
}

extension TestRepository: DeviceRepository where Record == Device {
    public init(devices: [Device] = [], failing: TestFailure = .none) {
        self.init(InMemoryRecordRepository(devices: devices), failing: failing)
    }

    public func fetchAll(of type: DeviceType) async throws -> [Device] {
        try await read { try await base.fetchAll(of: type) }
    }

    public func contains(name: String, type: DeviceType) async throws -> Bool {
        try await read { try await base.contains(name: name, type: type) }
    }
}

extension TestRepository: FilterPackRepository where Record == FilterPack {
    public init(filterPacks: [FilterPack] = [], failing: TestFailure = .none) {
        self.init(InMemoryRecordRepository(filterPacks: filterPacks), failing: failing)
    }

    public func use(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try await write { try await base.use(packID: packID, count: count) }
    }

    public func putBack(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try await write { try await base.putBack(packID: packID, count: count) }
    }
}
