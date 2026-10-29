import Foundation

// Decodable mirror of the web app's state (`localStorage["cj_v7"]`, see `src/core/state.js`).
//
// The web data is loosely typed and has drifted over versions: numbers are sometimes strings
// ("16.0", "93°C", "28с"), fields appear and disappear, and old entries miss newer fields.
// So every field is optional and numbers are decoded leniently. A malformed element is skipped
// instead of failing the whole import.

struct WebAppState: Decodable {
    var profile: WebProfile?
    var beans: LossyArray<WebBean>
    var filters: LossyArray<WebFilter>
    var equipment: LossyArray<WebDevice>
    var brews: LossyArray<WebBrew>
    var log: LossyArray<WebLogEntry>
    var trash: LossyArray<WebBrew>
    var achEarned: [String: LenientNumber]?
    var roasters: [String]?
    var beanNames: [String]?
    var milks: [String]?
    var juices: [String]?

    enum CodingKeys: String, CodingKey {
        case profile, beans, filters, equipment, brews, log, trash, achEarned, roasters, beanNames, milks, juices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try? container.decodeIfPresent(WebProfile.self, forKey: .profile)
        beans = container.lossyArray(forKey: .beans)
        filters = container.lossyArray(forKey: .filters)
        equipment = container.lossyArray(forKey: .equipment)
        brews = container.lossyArray(forKey: .brews)
        log = container.lossyArray(forKey: .log)
        trash = container.lossyArray(forKey: .trash)
        achEarned = try? container.decodeIfPresent([String: LenientNumber].self, forKey: .achEarned)
        roasters = container.lossyStrings(forKey: .roasters)
        beanNames = container.lossyStrings(forKey: .beanNames)
        milks = container.lossyStrings(forKey: .milks)
        juices = container.lossyStrings(forKey: .juices)
    }
}

struct WebProfile: Decodable {
    @Lenient var name: String?
    @Lenient var loc: String?
    @Lenient var cat: String?
    @Lenient var stazh: String?
    @Lenient var avEmoji: String?
    @Lenient var avColor: String?
}

struct WebBean: Decodable {
    var id: LenientNumber
    @Lenient var name: String?
    @Lenient var roaster: String?
    @Lenient var total: LenientNumber?
    @Lenient var current: LenientNumber?
    @Lenient var country: String?
    @Lenient var process: String?
    @Lenient var farm: String?
    @Lenient var score: LenientNumber?
    @Lenient var descriptors: String?
    @Lenient var roastType: String?
    @Lenient var _upd: LenientNumber?
}

struct WebDevice: Decodable {
    var id: LenientNumber
    @Lenient var name: String?
    @Lenient var type: String?
    @Lenient var _upd: LenientNumber?
}

struct WebFilter: Decodable {
    var id: LenientNumber
    @Lenient var name: String?
    @Lenient var total: LenientNumber?
    @Lenient var current: LenientNumber?
    @Lenient var _upd: LenientNumber?
}

struct WebBrew: Decodable {
    var id: LenientNumber
    @Lenient var ts: LenientNumber?
    @Lenient var beanName: String?
    @Lenient var roaster: String?
    @Lenient var roastType: String?
    @Lenient var beanId: LenientNumber?
    @Lenient var method: String?
    @Lenient var inverted: Bool?
    @Lenient var aeroFilters: LenientNumber?
    @Lenient var dripper: String?
    @Lenient var dripperId: LenientNumber?
    @Lenient var grinder: String?
    @Lenient var grinderId: LenientNumber?
    @Lenient var clicks: LenientNumber?
    @Lenient var temp: LenientNumber?
    @Lenient var ratio: LenientNumber?
    @Lenient var filter: String?
    @Lenient var filterId: LenientNumber?
    @Lenient var filterWet: Bool?
    @Lenient var espMachine: String?
    @Lenient var espMachineId: LenientNumber?
    @Lenient var accessories: LossyArray<LenientNumber>?
    @Lenient var dose: LenientNumber?
    @Lenient var steps: LossyArray<WebStep>?
    /// "3:05", "28с", "—" — or occasionally a bare number.
    @Lenient var totalTime: LenientText?
    @Lenient var espresso: WebEspresso?
    @Lenient var milk: WebMilk?
    @Lenient var ice: WebIce?
    @Lenient var rating: LenientNumber?
    @Lenient var flavors: LossyArray<String>?
    @Lenient var aroma: LossyArray<String>?
    @Lenient var notes: String?
    @Lenient var liked: Bool?
    @Lenient var manual: Bool?
    @Lenient var place: String?
    @Lenient var source: String?
    @Lenient var cafeVisit: Bool?
    @Lenient var _deletedAt: LenientNumber?
}

struct WebStep: Decodable {
    /// "pour" | "pause" | "action"
    @Lenient var type: String?
    /// Start offset, ms.
    @Lenient var t: LenientNumber?
    /// Duration, ms.
    @Lenient var ph: LenientNumber?
    /// Duration, s (older entries have only this).
    @Lenient var dur: LenientNumber?
    @Lenient var ml: LenientNumber?
    @Lenient var label: String?
}

struct WebEspresso: Decodable {
    @Lenient var dose: LenientNumber?
    @Lenient var targetYield: LenientNumber?
    @Lenient var actualYield: LenientNumber?
    @Lenient var shotTime: LenientNumber?
    @Lenient var tdsTarget: LenientNumber?
    @Lenient var tdsActual: LenientNumber?
    @Lenient var pressure: LenientNumber?
}

struct WebMilk: Decodable {
    @Lenient var name: String?
    @Lenient var temp: LenientNumber?
    @Lenient var vol: LenientNumber?
    @Lenient var frother: String?
}

struct WebIce: Decodable {
    @Lenient var amount: LenientNumber?
    @Lenient var mixer: String?
}

/// Journal/calendar entry. Wizard brews have a matching `WebBrew` with the same id;
/// some older or manual entries exist only here.
struct WebLogEntry: Decodable {
    @Lenient var id: LenientNumber?
    @Lenient var ts: LenientNumber?
    @Lenient var vol: LenientNumber?
    @Lenient var method: String?
    @Lenient var bean: String?
    @Lenient var rating: LenientNumber?
    @Lenient var dose: LenientNumber?
    @Lenient var ratio: LenientNumber?
    @Lenient var temp: LenientNumber?
    @Lenient var grinder: String?
    @Lenient var notes: String?
    @Lenient var place: String?
    @Lenient var source: String?
}
