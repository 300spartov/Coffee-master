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
    var ts: LenientNumber?
    var beanName: String?
    var roaster: String?
    var roastType: String?
    var beanId: LenientNumber?
    var method: String?
    var inverted: Bool?
    var aeroFilters: LenientNumber?
    var dripper: String?
    var dripperId: LenientNumber?
    var grinder: String?
    var grinderId: LenientNumber?
    var clicks: LenientNumber?
    var temp: LenientNumber?
    var ratio: LenientNumber?
    var filter: String?
    var filterId: LenientNumber?
    var filterWet: Bool?
    var espMachine: String?
    var espMachineId: LenientNumber?
    var accessories: [LenientNumber]?
    var dose: LenientNumber?
    var steps: LossyArray<WebStep>?
    var totalTime: String?
    var espresso: WebEspresso?
    var milk: WebMilk?
    var ice: WebIce?
    var rating: LenientNumber?
    var flavors: [String]?
    var aroma: [String]?
    var notes: String?
    var liked: Bool?
    var manual: Bool?
    var place: String?
    var source: String?
    var cafeVisit: Bool?
    var _deletedAt: LenientNumber?

    enum CodingKeys: String, CodingKey {
        case id, ts, beanName, roaster, roastType, beanId, method, inverted, aeroFilters, dripper, dripperId,
             grinder, grinderId, clicks, temp, ratio, filter, filterId, filterWet, espMachine, espMachineId,
             accessories, dose, steps, totalTime, espresso, milk, ice, rating, flavors, aroma, notes, liked,
             manual, place, source, cafeVisit, _deletedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(LenientNumber.self, forKey: .id)
        ts = c.lenient(.ts)
        beanName = c.string(.beanName)
        roaster = c.string(.roaster)
        roastType = c.string(.roastType)
        beanId = c.lenient(.beanId)
        method = c.string(.method)
        inverted = try? c.decodeIfPresent(Bool.self, forKey: .inverted)
        aeroFilters = c.lenient(.aeroFilters)
        dripper = c.string(.dripper)
        dripperId = c.lenient(.dripperId)
        grinder = c.string(.grinder)
        grinderId = c.lenient(.grinderId)
        clicks = c.lenient(.clicks)
        temp = c.lenient(.temp)
        ratio = c.lenient(.ratio)
        filter = c.string(.filter)
        filterId = c.lenient(.filterId)
        filterWet = try? c.decodeIfPresent(Bool.self, forKey: .filterWet)
        espMachine = c.string(.espMachine)
        espMachineId = c.lenient(.espMachineId)
        accessories = (try? c.decodeIfPresent(LossyArray<LenientNumber>.self, forKey: .accessories))?.elements
        dose = c.lenient(.dose)
        steps = try? c.decodeIfPresent(LossyArray<WebStep>.self, forKey: .steps)
        totalTime = c.string(.totalTime) ?? c.lenient(.totalTime).map { String($0.value) }
        espresso = try? c.decodeIfPresent(WebEspresso.self, forKey: .espresso)
        milk = try? c.decodeIfPresent(WebMilk.self, forKey: .milk)
        ice = try? c.decodeIfPresent(WebIce.self, forKey: .ice)
        rating = c.lenient(.rating)
        flavors = c.lossyStrings(forKey: .flavors)
        aroma = c.lossyStrings(forKey: .aroma)
        notes = c.string(.notes)
        liked = try? c.decodeIfPresent(Bool.self, forKey: .liked)
        manual = try? c.decodeIfPresent(Bool.self, forKey: .manual)
        place = c.string(.place)
        source = c.string(.source)
        cafeVisit = try? c.decodeIfPresent(Bool.self, forKey: .cafeVisit)
        _deletedAt = c.lenient(._deletedAt)
    }
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
