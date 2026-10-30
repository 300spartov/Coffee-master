// Generated from the web app's built-in device database (`src/core/data.js`, `DB`).
// Regenerate rather than edit by hand if the web catalog changes. Spec lines were corrected to
// Ukrainian here (a few were Russian in the web data); apply the same fixes to `data.js` before regenerating.

/// A device from the built-in catalog. Adding it to the inventory creates a `Device` with the same name.
public struct CatalogDevice: Hashable, Sendable, Identifiable {
    public let name: String
    /// Short spec line from the web catalog (Ukrainian), e.g. "Конус · пластик · 1 чашка".
    public let details: String

    public var id: String { name }
}

public enum DeviceCatalog {
    public static func devices(of type: DeviceType) -> [CatalogDevice] {
        switch type {
        case .dripper: dripper
        case .espressoMachine: espresso
        case .grinder: grinder
        case .kettle: kettle
        case .accessory: accessories
        case .filter: []  // Filter packs are tracked as stock, not picked from a catalog.
        }
    }

    private static let dripper: [CatalogDevice] = [
        CatalogDevice(name: "Hario V60 01", details: "Конус · пластик/кераміка/скло · 1 чашка"),
        CatalogDevice(name: "Hario V60 02", details: "Конус · пластик/кераміка/скло/мідь · 2 чашки"),
        CatalogDevice(name: "Hario V60 02 Metal", details: "Конус · нержавійка"),
        CatalogDevice(name: "Hario Switch", details: "Імерсія + пролив · V60"),
        CatalogDevice(name: "Origami Dripper S", details: "Конус · кераміка · 1–2 чашки"),
        CatalogDevice(name: "Origami Dripper M", details: "Конус · кераміка · 2–4 чашки · синій"),
        CatalogDevice(name: "Origami Air", details: "Конус · пластик · універсал"),
        CatalogDevice(name: "Fellow Stagg [X]", details: "Конус · нержавійка"),
        CatalogDevice(name: "Timemore Crystal Eye", details: "Конус · скло/пластик · V60"),
        CatalogDevice(name: "CAFEC Flower Dripper 4 cup", details: "Пелюстки · Tritan · 4 чашки"),
        CatalogDevice(name: "Cafec Flower Dripper S", details: "Пелюстки · пластик · 2 чашки"),
        CatalogDevice(name: "Sibarist FAST Cone", details: "Конус · пластик"),
        CatalogDevice(name: "Kono Meimon", details: "Конус · пластик"),
        CatalogDevice(name: "Cores C200", details: "Конус · фарфор · V60"),
        CatalogDevice(name: "Kalita Wave 155", details: "Плоске дно · нержавійка · 1–2 чашки"),
        CatalogDevice(name: "Kalita Wave 185", details: "Плоске дно · нержавійка · 2–4 чашки"),
        CatalogDevice(name: "Chemex 3-cup", details: "Боросилікат · 3 чашки"),
        CatalogDevice(name: "Chemex 6-cup", details: "Боросилікат · 6 чашок"),
        CatalogDevice(name: "Chemex 8-cup", details: "Боросилікат · 8 чашок"),
        CatalogDevice(name: "Melitta 1×4", details: "Плоске дно · пластик/кераміка"),
        CatalogDevice(name: "Clever Dripper", details: "Імерсія + фільтр"),
        CatalogDevice(name: "AeroPress Original", details: "Імерсія / тиск"),
        CatalogDevice(name: "AeroPress Go", details: "Імерсія / тиск · дорожній"),
        CatalogDevice(name: "AeroPress Clear", details: "Імерсія / тиск · прозорий"),
        CatalogDevice(name: "AeroPress XL", details: "Імерсія / тиск · великий об'єм"),
        CatalogDevice(name: "Bialetti Moka 3-cup", details: "Гейзерна · 3 чашки"),
        CatalogDevice(name: "Bialetti Moka 6-cup", details: "Гейзерна · 6 чашок"),
        CatalogDevice(name: "French Press 350ml", details: "Повне занурення"),
        CatalogDevice(name: "French Press 1L", details: "Повне занурення · 4–5 чашок"),
        CatalogDevice(name: "Hario Siphon 5-cup", details: "Сифон / вакуум"),
        CatalogDevice(name: "Hario Siphon Technica", details: "Сифон / вакуум"),
        CatalogDevice(name: "Delter Coffee Press", details: "Імерсія з тиском"),
        CatalogDevice(name: "Toddy Cold Brew System", details: "Імерсія · Cold Brew · 1.5л"),
        CatalogDevice(name: "Hario Mizudashi 1L", details: "Імерсія · Cold Brew · скло · 1л"),
        CatalogDevice(name: "Filtron Cold Brew", details: "Імерсія · Cold Brew"),
        CatalogDevice(name: "OXO Cold Brew Maker", details: "Імерсія · Cold Brew · 1л"),
        CatalogDevice(name: "Moccamaster KBGT-741", details: "Крапельна · Batch Brewing · 1.25л"),
        CatalogDevice(name: "Bonavita BV1900TS", details: "Крапельна · Batch Brewing · 1.4л"),
        CatalogDevice(name: "Fellow Aiden", details: "Крапельна · Batch Brewing · програмована"),
    ]

    private static let espresso: [CatalogDevice] = [
        CatalogDevice(name: "DeLonghi Dedica EC685", details: "Напівавтомат · термоблок"),
        CatalogDevice(name: "DeLonghi Dedica Duo EC9155", details: "Напівавтомат · термоблок"),
        CatalogDevice(name: "DeLonghi Stilosa EC230", details: "Напівавтомат · термоблок"),
        CatalogDevice(name: "Breville Bambino", details: "Напівавтомат · термоблок"),
        CatalogDevice(name: "Breville Bambino Plus", details: "Напівавтомат · термоблок"),
        CatalogDevice(name: "Nespresso Vertuo Pop", details: "Капсульна"),
        CatalogDevice(name: "Breville Barista Express", details: "Зі вбудованою кавомолкою"),
        CatalogDevice(name: "Breville Barista Express Impress", details: "Зі вбудованою кавомолкою"),
        CatalogDevice(name: "Breville Barista Pro", details: "Напівавтомат · термоблок"),
        CatalogDevice(name: "Breville Barista Touch", details: "Напівавтомат · тачскрін"),
        CatalogDevice(name: "Gaggia Classic Pro", details: "Напівавтомат · однобойлер"),
        CatalogDevice(name: "Gaggia Classic Evo Pro", details: "Напівавтомат · однобойлер"),
        CatalogDevice(name: "Rancilio Silvia", details: "Напівавтомат · однобойлер"),
        CatalogDevice(name: "Rancilio Silvia Pro X", details: "Напівавтомат · подвійний бойлер"),
        CatalogDevice(name: "Lelit Mara X", details: "Напівавтомат · HX бойлер"),
        CatalogDevice(name: "Lelit Bianca V3", details: "Напівавтомат · подвійний бойлер"),
        CatalogDevice(name: "ECM Classika PID", details: "Напівавтомат · однобойлер"),
        CatalogDevice(name: "La Marzocco Linea Mini", details: "Проф. · подвійний бойлер"),
        CatalogDevice(name: "La Marzocco GS3 MP", details: "Проф. · подвійний бойлер"),
        CatalogDevice(name: "Rocket Appartamento", details: "Напівавтомат · HX бойлер"),
        CatalogDevice(name: "Rocket R58 Cinquantotto", details: "Напівавтомат · подвійний бойлер"),
        CatalogDevice(name: "Decent DE1", details: "Напівавтомат · профілі тиску"),
        CatalogDevice(name: "ECM Synchronika", details: "Напівавтомат · подвійний бойлер"),
        CatalogDevice(name: "Profitec Pro 700", details: "Напівавтомат · подвійний бойлер"),
        CatalogDevice(name: "Slayer Single Group", details: "Проф. · HX бойлер"),
        CatalogDevice(name: "Flair 58", details: "Ручний важільний · 58мм"),
        CatalogDevice(name: "Flair NEO Flex", details: "Ручний еспресо"),
        CatalogDevice(name: "ROK Espresso", details: "Ручний важільний еспресо"),
        CatalogDevice(name: "Wacaco Nanopresso", details: "Портативний еспресо"),
        CatalogDevice(name: "Wacaco Picopresso", details: "Портативний еспресо"),
        CatalogDevice(name: "Cafflano Kompresso", details: "Портативний еспресо"),
        CatalogDevice(name: "Cafelat Robot", details: "Ручний важільний"),
    ]

    private static let grinder: [CatalogDevice] = [
        CatalogDevice(name: "Comandante C40 MK4", details: "Ручна · нитробладе сталь · 40мм"),
        CatalogDevice(name: "1Zpresso X-Ultra", details: "Ручна · сталь · 40мм"),
        CatalogDevice(name: "1Zpresso J-Ultra", details: "Ручна · сталь · 48мм · еспресо"),
        CatalogDevice(name: "1Zpresso K-Ultra", details: "Ручна · сталь · 48мм · фільтр"),
        CatalogDevice(name: "1Zpresso Q2", details: "Ручна · сталь · 38мм · тревел"),
        CatalogDevice(name: "Timemore C3", details: "Ручна · сталь · 38мм"),
        CatalogDevice(name: "Timemore C3 Pro", details: "Ручна · сталь · 38мм"),
        CatalogDevice(name: "Timemore C3 ESP", details: "Ручна · сталь · 38мм · еспресо"),
        CatalogDevice(name: "Timemore Chestnut X", details: "Ручна · сталь · 38мм"),
        CatalogDevice(name: "Kinu M47 Classic", details: "Ручна · сталь · 47мм"),
        CatalogDevice(name: "Kinu M47 Phoenix", details: "Ручна · сталь · 47мм"),
        CatalogDevice(name: "Kinu M68", details: "Ручна · сталь · 68мм · еспресо"),
        CatalogDevice(name: "Orphan Espresso Lido E", details: "Ручна · сталь · 48мм"),
        CatalogDevice(name: "Hario Skerton Plus", details: "Ручна · кераміка · 38мм"),
        CatalogDevice(name: "Hario Mini Mill Plus", details: "Ручна · кераміка · 28мм"),
        CatalogDevice(name: "Porlex Mini II", details: "Ручна · кераміка · 35мм"),
        CatalogDevice(name: "Varia VS3", details: "Ручна · сталь · 48мм"),
        CatalogDevice(name: "Fellow Ode Gen 2", details: "Електро · плоскі · 64мм"),
        CatalogDevice(name: "Fellow Opus", details: "Електро · конічні · 40мм"),
        CatalogDevice(name: "Baratza Encore ESP", details: "Електро · конічні · 40мм"),
        CatalogDevice(name: "Baratza Virtuoso+", details: "Електро · конічні · 40мм"),
        CatalogDevice(name: "Baratza Sette 270", details: "Електро · конічні · 40мм"),
        CatalogDevice(name: "OXO Brew Conical Burr", details: "Електро · конічні · 40мм"),
        CatalogDevice(name: "Breville Smart Grinder Pro", details: "Електро · конічні · 40мм"),
        CatalogDevice(name: "Timemore Electric Nano", details: "Електро · конічні · 38мм"),
        CatalogDevice(name: "Wilfa Svart", details: "Електро · конічні · 40мм"),
        CatalogDevice(name: "Eureka Mignon Filtro", details: "Електро · плоскі · 50мм"),
        CatalogDevice(name: "Niche Zero", details: "Електро · конічні · 63мм"),
        CatalogDevice(name: "Niche Duo", details: "Електро · конічні · 63мм"),
        CatalogDevice(name: "Mahlkönig X54", details: "Електро · плоскі · 54мм"),
        CatalogDevice(name: "Mahlkönig EK43", details: "Проф. · плоскі · 98мм"),
        CatalogDevice(name: "Eureka Mignon Specialita", details: "Електро · плоскі · 55мм"),
        CatalogDevice(name: "Eureka Atom 75", details: "Електро · плоскі · 75мм"),
        CatalogDevice(name: "Mazzer Mini", details: "Проф. · конічні · 58мм"),
        CatalogDevice(name: "DF64 Gen 2", details: "Електро · плоскі · 64мм"),
        CatalogDevice(name: "DF83 V2", details: "Електро · плоскі · 83мм"),
        CatalogDevice(name: "Option-O Lagom P64", details: "Електро · плоскі · 64мм"),
    ]

    private static let kettle: [CatalogDevice] = [
        CatalogDevice(name: "Fellow Stagg EKG", details: "Електро · 0.9л · 60–100°C ±1°"),
        CatalogDevice(name: "Fellow Stagg EKG Pro", details: "Електро · 1.0л · 60–100°C ±1°"),
        CatalogDevice(name: "Fellow Corvo EKG", details: "Електро · 0.9л · 60–100°C"),
        CatalogDevice(name: "Brewista Artisan", details: "Електро · 1.0л · 40–100°C ±1°"),
        CatalogDevice(name: "Hario Buono V60 Electric", details: "Електро · 0.8л · до 100°C"),
        CatalogDevice(name: "Hario Smart G", details: "Електро · 0.8л · 60–100°C"),
        CatalogDevice(name: "Cosori Gooseneck", details: "Електро · 0.8л · 40–100°C"),
        CatalogDevice(name: "Bodum Melior", details: "Електро · 0.8л · до 100°C"),
        CatalogDevice(name: "Bonavita BKE820XL", details: "Електро · 1.0л · до 100°C"),
        CatalogDevice(name: "KitchenAid Precision", details: "Електро · 1.5л · 40–100°C"),
        CatalogDevice(name: "Timemore Fish Smart", details: "Електро · 0.8л · 40–100°C"),
        CatalogDevice(name: "Normcore Pour-over", details: "Електро · 1.0л · 40–100°C"),
        CatalogDevice(name: "Hario Buono Stovetop", details: "Плита · нержавійка · 1.2л"),
        CatalogDevice(name: "Takahiro", details: "Плита · нержавійка · 0.5–0.9л"),
        CatalogDevice(name: "Kalita Wave Kettle", details: "Плита · нержавійка · 0.7л"),
    ]

    private static let accessories: [CatalogDevice] = [
        CatalogDevice(name: "Acaia Pearl", details: "Ваги · 0.1г · таймер · Bluetooth"),
        CatalogDevice(name: "Acaia Pearl S", details: "Ваги еспресо · 0.1г · Bluetooth"),
        CatalogDevice(name: "Acaia Lunar S", details: "Ваги еспресо · 0.1г · Bluetooth"),
        CatalogDevice(name: "Acaia Pyxis", details: "Ваги еспресо · 0.1г · Bluetooth"),
        CatalogDevice(name: "Timemore Black Mirror Pro", details: "Ваги · 0.1г · таймер"),
        CatalogDevice(name: "Timemore Black Mirror Basic 2", details: "Ваги · 0.1г · таймер"),
        CatalogDevice(name: "Timemore Cube 3.0", details: "Ваги еспресо · 0.1г"),
        CatalogDevice(name: "Fellow Tally Pro", details: "Ваги · 0.1г · таймер"),
        CatalogDevice(name: "Fellow Tally", details: "Ваги · 1г · таймер"),
        CatalogDevice(name: "Hario V60 Drip Scale", details: "Ваги · 0.1г · таймер"),
        CatalogDevice(name: "Normcore Pocket Scale V3", details: "Ваги еспресо · 0.1г"),
        CatalogDevice(name: "Pullman Big Step Tamper", details: "Темпер · 57–58.5мм"),
        CatalogDevice(name: "Normcore Spring V4", details: "Темпер калібрований · 45.5–58.5мм"),
        CatalogDevice(name: "Barista Hustle Tamper", details: "Темпер · 58.4мм"),
        CatalogDevice(name: "Cafelat Tamper", details: "Темпер · 58мм"),
        CatalogDevice(name: "Normcore Heavy Distributor", details: "Дистрибʼютор · 58.5мм"),
        CatalogDevice(name: "Ona Coffee OCD v3", details: "Дистрибʼютор · пропелер · 58мм"),
        CatalogDevice(name: "Nucleus NCD", details: "Дистрибʼютор · пропелер · 58.5мм"),
        CatalogDevice(name: "WDT Tool", details: "Голка для розподілу"),
        CatalogDevice(name: "Fellow Prismo", details: "Металевий фільтр для AeroPress"),
        CatalogDevice(name: "Fellow Atmos Canister", details: "Вакуумне зберігання кави"),
        CatalogDevice(name: "Airscape Canister", details: "Зберігання кави"),
        CatalogDevice(name: "Normcore Puck Screen 58мм", details: "Диспершн-скрин"),
        CatalogDevice(name: "VST Precision Basket 58мм", details: "Кошик портафільтра"),
        CatalogDevice(name: "Dosing Funnel", details: "Воронка для дозування"),
        CatalogDevice(name: "Knock Box", details: "Контейнер для жмиху"),
        CatalogDevice(name: "Hario Server 600ml", details: "Джаг · скло"),
        CatalogDevice(name: "Fellow Stagg Server", details: "Джаг з термометром"),
    ]
}
