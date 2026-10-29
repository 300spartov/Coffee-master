/// Which records a query sees with respect to the trash (`Syncable.deletedAt`).
public enum DeletedFilter: Sendable {
    /// Active records only (normal lists).
    case exclude
    /// Trashed records only (the trash).
    case only
    /// Both.
    case include

    public func matches(_ record: some Syncable) -> Bool {
        switch self {
        case .exclude: !record.isDeleted
        case .only: record.isDeleted
        case .include: true
        }
    }
}
