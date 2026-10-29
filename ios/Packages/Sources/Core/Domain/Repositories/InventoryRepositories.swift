import Foundation

/// Coffee bags, most recently updated first.
public protocol BeanRepository: RecordRepository where Record == Bean {
    /// Takes `grams` out of the bag (never below zero) and returns the updated bag.
    @discardableResult
    func consume(beanID: Bean.ID, grams: Double) async throws -> Bean
    /// Puts `grams` back (never above the bag size) and returns the updated bag.
    @discardableResult
    func restock(beanID: Bean.ID, grams: Double) async throws -> Bean
}

/// Owned equipment, ordered by type then name.
public protocol DeviceRepository: RecordRepository where Record == Device {
    func fetchAll(of type: DeviceType) async throws -> [Device]
    /// Case-insensitive name match within a type, used to avoid adding a catalog device twice.
    func contains(name: String, type: DeviceType) async throws -> Bool
}

/// Paper filter packs, most recently updated first.
public protocol FilterPackRepository: RecordRepository where Record == FilterPack {
    @discardableResult
    func use(packID: FilterPack.ID, count: Int) async throws -> FilterPack
    @discardableResult
    func putBack(packID: FilterPack.ID, count: Int) async throws -> FilterPack
}
