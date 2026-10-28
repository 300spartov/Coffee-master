import CryptoKit
import Foundation
import Domain

/// Everything recovered from a web app export, as Domain models ready to be stored.
public struct WebImport: Sendable, Equatable {
    public var profile: UserProfile?
    public var beans: [Bean]
    public var devices: [Device]
    public var filterPacks: [FilterPack]
    /// Includes trashed brews (with `deletedAt` set).
    public var brews: [Brew]
    public var achievements: [EarnedAchievement]
    public var suggestions: Suggestions

    public init(
        profile: UserProfile? = nil,
        beans: [Bean] = [],
        devices: [Device] = [],
        filterPacks: [FilterPack] = [],
        brews: [Brew] = [],
        achievements: [EarnedAchievement] = [],
        suggestions: Suggestions = Suggestions()
    ) {
        self.profile = profile
        self.beans = beans
        self.devices = devices
        self.filterPacks = filterPacks
        self.brews = brews
        self.achievements = achievements
        self.suggestions = suggestions
    }

    public var isEmpty: Bool {
        beans.isEmpty && devices.isEmpty && filterPacks.isEmpty && brews.isEmpty && achievements.isEmpty
    }
}

public enum WebImportError: Error, Equatable {
    /// Not valid JSON at all.
    case invalidJSON
    /// Valid JSON, but not a Coffee Master web export.
    case unrecognizedFormat
}

/// Converts the web app's JSON export (`localStorage["cj_v7"]`) into Domain models.
///
/// IDs are **deterministic**: the same web record always maps to the same UUID
/// (`id(for:legacyID:)`). Importing a file twice, or on two devices, yields identical records,
/// so storage and sync deduplicate naturally.
public enum WebImporter {
    public enum EntityKind: String, Sendable {
        case brew, bean, device, filter
    }

    /// `updatedAt` for web records that never stored `_upd`. Fixed (not the import time) so
    /// re-imports are byte-identical, and old enough that any local edit wins over it.
    public static let unknownUpdateDate = Date(timeIntervalSince1970: 0)

    public static func decode(_ data: Data, importedAt: Date = .now) throws -> WebImport {
        let state = try parseState(data)
        return map(state, importedAt: importedAt)
    }

    /// Stable UUID for a web record (name-based, SHA-256, RFC 4122 version 5 layout).
    public static func id(for kind: EntityKind, legacyID: Int) -> UUID {
        let digest = SHA256.hash(data: Data("coffeemaster.web.\(kind.rawValue).\(legacyID)".utf8))
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    // MARK: - Parsing

    private static let knownKeys: Set<String> = ["brews", "beans", "log", "equipment", "filters", "profile", "trash"]

    private static func parseState(_ data: Data) throws -> WebAppState {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WebImportError.invalidJSON
        }
        // Accept both the raw state and a backend row wrapper: { "data": { …state… } }.
        let stateObject: [String: Any]
        if let wrapped = object["data"] as? [String: Any], !knownKeys.isDisjoint(with: wrapped.keys) {
            stateObject = wrapped
        } else {
            stateObject = object
        }
        guard !knownKeys.isDisjoint(with: stateObject.keys) else {
            throw WebImportError.unrecognizedFormat
        }
        let stateData = try JSONSerialization.data(withJSONObject: stateObject)
        do {
            return try JSONDecoder().decode(WebAppState.self, from: stateData)
        } catch {
            throw WebImportError.unrecognizedFormat
        }
    }

    // MARK: - Mapping

    private static func map(_ state: WebAppState, importedAt: Date) -> WebImport {
        let trashed = state.trash.elements.map { mapBrew($0, logEntry: nil, importedAt: importedAt, isTrashed: true) }
        let trashedIDs = Set(state.trash.elements.map(\.id.int))

        let logByID = Dictionary(
            state.log.elements.compactMap { entry in entry.id.map { ($0.int, entry) } },
            uniquingKeysWith: { first, _ in first }
        )

        var seenBrewIDs = Set<Int>()
        let active: [Brew] = state.brews.elements.compactMap { brew in
            let legacyID = brew.id.int
            guard !trashedIDs.contains(legacyID), seenBrewIDs.insert(legacyID).inserted else { return nil }
            return mapBrew(brew, logEntry: logByID[legacyID], importedAt: importedAt, isTrashed: false)
        }

        // Journal entries without a brew record (older versions / quick logs) become manual brews.
        let logOnly: [Brew] = state.log.elements.compactMap { entry in
            guard let legacyID = entry.id?.int,
                  !trashedIDs.contains(legacyID),
                  seenBrewIDs.insert(legacyID).inserted
            else { return nil }
            return mapLogOnlyEntry(entry, legacyID: legacyID, importedAt: importedAt)
        }

        let brews = (active + logOnly + trashed).sorted { $0.date > $1.date }

        return WebImport(
            profile: state.profile.map { mapProfile($0, importedAt: importedAt) },
            beans: unique(state.beans.elements.map { mapBean($0, importedAt: importedAt) }),
            devices: unique(state.equipment.elements.map { mapDevice($0, importedAt: importedAt) }),
            filterPacks: unique(state.filters.elements.map { mapFilter($0, importedAt: importedAt) }),
            brews: brews,
            achievements: (state.achEarned ?? [:])
                .map { EarnedAchievement(achievementID: $0.key, earnedAt: timestamp($0.value.value)) }
                .sorted { $0.earnedAt < $1.earnedAt },
            suggestions: Suggestions(
                roasters: cleaned(state.roasters),
                beanNames: cleaned(state.beanNames),
                milks: cleaned(state.milks),
                mixers: cleaned(state.juices)
            )
        )
    }

    private static func mapBrew(_ web: WebBrew, logEntry: WebLogEntry?, importedAt: Date, isTrashed: Bool) -> Brew {
        let legacyID = web.id.int
        let date = web.ts.map { timestamp($0.value) } ?? importedAt
        let deletedAt = isTrashed ? (web._deletedAt.map { timestamp($0.value) } ?? importedAt) : nil
        let espresso = web.espresso.map(mapEspresso)
        let method = BrewMethod(rawValue: nonEmpty(web.method) ?? (espresso != nil ? BrewMethod.espresso.rawValue : BrewMethod.v60.rawValue))
        let isManual = web.manual ?? false

        return Brew(
            id: id(for: .brew, legacyID: legacyID),
            legacyID: legacyID,
            date: date,
            updatedAt: deletedAt ?? date,
            deletedAt: deletedAt,
            method: method,
            bean: nonEmpty(web.beanName).map {
                BeanReference(
                    beanID: web.beanId.map { id(for: .bean, legacyID: $0.int) },
                    name: $0,
                    roaster: web.roaster ?? "",
                    roastProfile: web.roastType.flatMap(RoastProfile.init(rawValue:))
                )
            },
            dripper: gear(web.dripper, id: web.dripperId, kind: .device),
            grinder: gear(web.grinder, id: web.grinderId, kind: .device),
            grindSetting: web.clicks.map(\.int).flatMap { $0 > 0 ? $0 : nil },
            filter: gear(web.filter, id: web.filterId, kind: .filter),
            isFilterRinsed: web.filter.flatMap(nonEmpty) != nil ? web.filterWet : nil,
            espressoMachine: gear(web.espMachine, id: web.espMachineId, kind: .device),
            accessoryIDs: (web.accessories ?? []).map { id(for: .device, legacyID: $0.int) },
            aeropress: method.rawValue.lowercased().contains("aero") && (web.inverted != nil || web.aeroFilters != nil)
                ? AeroPressOptions(isInverted: web.inverted ?? false, filterCount: max(web.aeroFilters?.int ?? 1, 1))
                : nil,
            doseGrams: web.dose?.value ?? espresso?.doseGrams ?? 16,
            ratio: web.ratio?.value ?? (espresso != nil ? 2 : 16),
            waterTemperature: web.temp?.value,
            steps: (web.steps?.elements ?? []).compactMap(mapStep),
            totalTime: espresso?.shotTime ?? parseDuration(web.totalTime),
            beverageVolume: isManual ? logEntry?.vol?.value : nil,
            espresso: espresso,
            milk: web.milk.flatMap(mapMilk),
            ice: web.ice.flatMap(mapIce),
            rating: web.rating?.value ?? 8,
            flavors: web.flavors ?? [],
            aromas: web.aroma ?? [],
            notes: web.notes ?? "",
            origin: origin(cafeVisit: web.cafeVisit, source: web.source, place: web.place),
            isManual: isManual,
            isLiked: web.liked ?? false
        )
    }

    private static func mapLogOnlyEntry(_ entry: WebLogEntry, legacyID: Int, importedAt: Date) -> Brew {
        let date = entry.ts.map { timestamp($0.value) } ?? importedAt
        let method = BrewMethod(rawValue: nonEmpty(entry.method) ?? BrewMethod.v60.rawValue)
        return Brew(
            id: id(for: .brew, legacyID: legacyID),
            legacyID: legacyID,
            date: date,
            method: method,
            bean: nonEmpty(entry.bean).map { BeanReference(name: $0) },
            grinder: nonEmpty(entry.grinder).map { GearReference(name: $0) },
            doseGrams: entry.dose?.value ?? 16,
            ratio: entry.ratio?.value ?? (method.isEspressoBased ? 2 : 16),
            waterTemperature: entry.temp?.value,
            beverageVolume: entry.vol?.value,
            rating: entry.rating?.value ?? 8,
            notes: entry.notes ?? "",
            origin: origin(cafeVisit: nil, source: entry.source, place: entry.place),
            isManual: true
        )
    }

    private static func mapStep(_ web: WebStep) -> BrewStep? {
        let start = (web.t?.value ?? 0) / 1_000
        let duration = web.ph.map { $0.value / 1_000 } ?? web.dur?.value ?? 0
        let kind: BrewStep.Kind
        switch web.type {
        case "pour":
            kind = .pour(milliliters: web.ml?.value ?? 0)
        case "pause":
            kind = .pause
        case "action":
            kind = .action(action(fromLabel: web.label))
        default:
            return nil
        }
        return BrewStep(kind: kind, start: max(start, 0), duration: max(duration, 0))
    }

    private static func action(fromLabel label: String?) -> BrewAction {
        switch label?.lowercased() {
        case "чавимо", "press": .press
        case "перемішати", "помішати", "stir": .stir
        case "покрутити", "закрутити", "swirl": .swirl
        case "струсити", "shake": .shake
        case let other?: BrewAction(rawValue: other)
        case nil: .stir
        }
    }

    private static func mapEspresso(_ web: WebEspresso) -> EspressoShot {
        let dose = web.dose?.value ?? 18
        return EspressoShot(
            doseGrams: dose,
            targetYieldGrams: web.targetYield?.value ?? dose * 2,
            actualYieldGrams: positive(web.actualYield),
            shotTime: web.shotTime?.value ?? 0,
            targetTDS: positive(web.tdsTarget),
            actualTDS: positive(web.tdsActual),
            pressureBar: positive(web.pressure)
        )
    }

    private static func mapMilk(_ web: WebMilk) -> MilkInfo? {
        let name = web.name ?? ""
        guard !name.isEmpty || web.vol != nil || web.temp != nil else { return nil }
        return MilkInfo(name: name, temperature: positive(web.temp), volumeMilliliters: positive(web.vol), frother: web.frother ?? "")
    }

    private static func mapIce(_ web: WebIce) -> IceInfo? {
        guard web.amount != nil || nonEmpty(web.mixer) != nil else { return nil }
        return IceInfo(amountGrams: positive(web.amount), mixer: web.mixer ?? "")
    }

    private static func mapBean(_ web: WebBean, importedAt: Date) -> Bean {
        let total = web.total?.value ?? Bean.defaultBagGrams
        return Bean(
            id: id(for: .bean, legacyID: web.id.int),
            legacyID: web.id.int,
            updatedAt: web._upd.map { timestamp($0.value) } ?? unknownUpdateDate,
            name: web.name ?? "",
            roaster: web.roaster ?? "",
            totalGrams: total,
            remainingGrams: web.current?.value ?? total,
            country: web.country ?? "",
            farm: web.farm ?? "",
            process: nonEmpty(web.process).map(ProcessingMethod.init(rawValue:)),
            score: positive(web.score),
            descriptors: web.descriptors ?? "",
            roastProfile: web.roastType.flatMap(RoastProfile.init(rawValue:))
        )
    }

    private static func mapDevice(_ web: WebDevice, importedAt: Date) -> Device {
        Device(
            id: id(for: .device, legacyID: web.id.int),
            legacyID: web.id.int,
            updatedAt: web._upd.map { timestamp($0.value) } ?? unknownUpdateDate,
            name: web.name ?? "",
            type: web.type.flatMap(DeviceType.init(rawValue:)) ?? .accessory
        )
    }

    private static func mapFilter(_ web: WebFilter, importedAt: Date) -> FilterPack {
        let total = web.total?.int ?? FilterPack.defaultCount
        return FilterPack(
            id: id(for: .filter, legacyID: web.id.int),
            legacyID: web.id.int,
            updatedAt: web._upd.map { timestamp($0.value) } ?? unknownUpdateDate,
            name: web.name ?? "",
            total: total,
            remaining: web.current?.int ?? total
        )
    }

    private static func mapProfile(_ web: WebProfile, importedAt: Date) -> UserProfile {
        UserProfile(
            name: web.name ?? "",
            location: web.loc ?? "",
            title: web.cat ?? "",
            experience: web.stazh ?? "",
            avatar: Avatar(emoji: nonEmpty(web.avEmoji), colorHex: nonEmpty(web.avColor)),
            updatedAt: importedAt
        )
    }

    // MARK: - Helpers

    private static func gear(_ name: String?, id legacyID: LenientNumber?, kind: EntityKind) -> GearReference? {
        guard let name = nonEmpty(name) else { return nil }
        return GearReference(id: legacyID.map { id(for: kind, legacyID: $0.int) }, name: name)
    }

    private static func origin(cafeVisit: Bool?, source: String?, place: String?) -> BrewOrigin {
        let place = nonEmpty(place)
        if cafeVisit == true || source == "place" || place != nil {
            return .cafe(place: place ?? "")
        }
        return .home
    }

    /// "3:05" → 185, "28с" / "28s" → 28, "—" → nil.
    static func parseDuration(_ string: String?) -> TimeInterval? {
        guard let string = nonEmpty(string) else { return nil }
        let parts = string.split(separator: ":")
        if parts.count == 2, let minutes = Double(parts[0]), let seconds = LenientNumber.parse(String(parts[1])) {
            return minutes * 60 + seconds
        }
        return LenientNumber.parse(string)
    }

    private static func timestamp(_ milliseconds: Double) -> Date {
        Date(timeIntervalSince1970: milliseconds / 1_000)
    }

    private static func positive(_ number: LenientNumber?) -> Double? {
        guard let value = number?.value, value > 0 else { return nil }
        return value
    }

    private static func nonEmpty(_ string: String?) -> String? {
        guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func cleaned(_ list: [String]?) -> [String] {
        (list ?? []).reduce(into: []) { result, value in result = Suggestions.adding(value, to: result) }
    }

    private static func unique<T: Syncable>(_ records: [T]) -> [T] {
        var seen = Set<UUID>()
        return records.filter { seen.insert($0.id).inserted }
    }
}
