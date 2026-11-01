import CoreData
import Domain

/// Keeps inventory in step with the trash, like the web app (`softDeleteBrew` / `restoreBrew`):
/// trashing a brew puts its dose back into the bean bag and one filter back into the pack;
/// restoring takes them out again. Runs inside the same transaction as the brew change.
enum BrewStockEffects {
    enum Direction {
        case returnToStock
        case takeFromStock
    }

    /// Returns the bag and pack after the change.
    @discardableResult
    static func apply(_ direction: Direction, for brew: Brew, in context: NSManagedObjectContext) throws -> StockUsage {
        var usage = StockUsage()
        if let beanID = brew.bean?.beanID, brew.doseGrams > 0 {
            usage.bean = try ignoringMissing {
                try RecordStore<Bean>.mutate(id: beanID, in: context) { bean in
                    switch direction {
                    case .returnToStock: bean.restock(grams: brew.doseGrams)
                    case .takeFromStock: bean.consume(grams: brew.doseGrams)
                    }
                }
            }
        }
        if let packID = brew.filter?.id {
            usage.filterPack = try ignoringMissing {
                try RecordStore<FilterPack>.mutate(id: packID, in: context) { pack in
                    switch direction {
                    case .returnToStock: pack.putBack()
                    case .takeFromStock: pack.use()
                    }
                }
            }
        }
        return usage
    }

    /// The bag or pack may have been deleted since; that's fine, there's nothing to adjust.
    private static func ignoringMissing<T>(_ body: () throws -> T) throws -> T? {
        do {
            return try body()
        } catch RepositoryError.notFound {
            return nil
        }
    }
}
