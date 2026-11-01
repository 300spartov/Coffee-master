# Native iOS Roadmap — porting the Coffee Master web app

Source of truth: the web app in `src/` (a Telegram Mini App, about 6.7k lines of JS).
Target: this iOS project (MVVM + Router, SwiftUI screens, UIKit navigation, modular SPM).

Each step below is a **PR-sized slice**: it builds, has tests, and can be merged on its own.
Size: **S** ≈ 1–2 days, **M** ≈ 3–5 days, **L** ≈ 1–2 weeks.

---

## Decisions needed before / during Phase 0

| # | Question | Why it matters | Recommendation |
|---|---|---|---|
| D1 | **Accounts — decided.** **Sign in with Apple** against **our own backend**. No Telegram login, no Supabase. | Defines the auth flow and the API contract. | The app sends Apple's identity token to the backend, which verifies it with Apple and returns its own access + refresh tokens (stored in the Keychain). |
| D2 | **Existing web/Telegram data — decided.** Import via JSON. | Existing users can move their history over. | One-time import of a web JSON export (`cj_v7`) from Settings → "Import from web app" (file picker). Importing is idempotent: records are matched by web `id`, so running it twice doesn't create duplicates. Imported records are then synced to the backend like any local data. |
| D3 | **Local storage & sync model — decided: Core Data.** Our own backend means we design the API instead of inheriting the web's whole-blob merge. | Affects Phase 0 storage and Phase 5. | Core Data behind repository protocols, so features never see it. Codable domain models that can still decode the web JSON (D2). Per-record sync through a REST API (`updatedAt` + soft delete, last-write-wins). |
| D4 | **Release scope.** | Decides whether sync blocks the first TestFlight build. | Beta = Phases 0–5 (includes sync). Market and Community come after. |
| D5 | **Languages — decided.** UA (default) + EN. The web app has ~700 keys in `core/i18n.js`. Some catalog data (devices, flavors) is in UA/RU. | String Catalog setup. | `Localizable.xcstrings` with UA + EN. Keep data catalogs as-is, localize later. |
| D6 | **Tooling — decided.** DI: **[Factory](https://github.com/hmlongco/Factory)** 2.5 via `FactoryKit` (adopted). Networking: **[Alamofire](https://github.com/Alamofire/Alamofire)** (added with the networking module in 5.2). | Shapes every module. | Keys with preview-safe defaults live in the owning module; the app registers real implementations; tests use the `FactoryTesting` `.container` trait. |

---

## Phase 0 — Foundation (replace template samples with the real domain)

| Step | What | Web source | iOS | Size |
|---|---|---|---|---|
| 0.1 ✅ | **Domain models**: `Brew` (alternative + espresso, steps, milk/ice, tasting, origin), `Bean`, `Device`, `FilterPack`, `UserProfile`, `EarnedAchievement`, `Suggestions`. All records are `Syncable` (UUID, `updatedAt`, soft `deletedAt`) and carry an optional `legacyID`. Open string-backed types for method, process and action. **`WebImport` module**: lenient decoder for the web JSON plus a mapper to Domain, with deterministic IDs. | `core/state.js`, `brew/save.js`, `brew/espresso/espresso.js` | `Domain`, `WebImport` | M |
| 0.2 ✅ | **Local store (Core Data)**: model defined in code in `DataLayer`, with indexed query columns plus a JSON payload of the Domain struct. `PersistenceController` (App Group container with an Application Support fallback, short-lived background contexts, persistent history tracking with transaction authors, per-entity change streams). Generic `RecordStore` (upsert with last-write-wins or overwrite, unchanged detection, soft delete, restore, purge). `DocumentStore` for profile, achievements and suggestions. Core Data repositories replace the in-memory one. **`WebImportService`**: one transaction, idempotent, keeps local edits, merges achievements and suggestions. Settings → "Import from Web App" (Files picker + toast). Not done yet: merging changes written by other processes (needed once widgets or App Intents write); history purge (needed with sync in Phase 5). | `core/state.js` | `DataLayer` | L |
| 0.2b ✅ | **Web app: "Export data" button** (Settings) that downloads or shares `cj_v7` as a `.json` file, so users can move their data to iOS. Done on branch `web/export-data`: Profile → "Експорт даних (для iOS)", shares or downloads `coffee-master-YYYY-MM-DD.json`. | `core/state.js` | web | S |
| 0.3 ✅ | **Repositories**: Domain protocols `BrewRepository`, `BeanRepository` (consume/restock), `DeviceRepository` (by type, duplicate check), `FilterPackRepository` (use/put back), `TrashRepository` (restore, delete permanently, empty, purge after 30 days), `ProfileRepository` (profile + achievements), `SuggestionsRepository`. Core Data implementations in `DataLayer`, in-memory ones as DI defaults for previews and tests. Trashing a brew returns its dose and filter to stock and restoring takes them again, in one transaction (as in the web app). Expired trash is purged at launch. | `features/trash`, `features/beans`, `features/devices` | `Domain`, `DataLayer` | S |
| 0.4 ✅ | **Design system v2**: all colors in the **Theme** (`ColorPalette` + `LightTheme` / `DarkTheme`, light/dark follow the system; new roles `fill`, `accentSoft`), **amber accent** from the web app, **system keyboards** (no custom numpad), **toasts**. Components: `Card` / `.cardStyle()`, `Chip` + `ChipGroup` (wrapping `FlowLayout`), `SectionHeader`, `StockBar` + `StockLevel`, `RatingRing`, `RatingView`, `IconBadge`, `MetricView`, `StatTile`, `NumberField` (decimal keyboard, clamped), primary/secondary button styles, empty/error/loading states with an action, text styles (`.appTextStyle(…)`). Segmented controls use the native `Picker(.segmented)`. Debug **Design System gallery**: Settings → Developer, or `coffeemaster://settings/design-system`. | `core/base.css`, `layout.css`, `overlays.css` | `DesignSystem` | M |
| 0.5 ✅ | **i18n**: a String Catalog per module (`Resources/Localizable.xcstrings`) plus the app's own, Ukrainian and English. An in-app **language switch** (Settings → General → Language) applies immediately by rebuilding the screens. Lookups go through `tr("…")` → `L10n`, pinned to the chosen language and the module's bundle, so all modules always agree. Default: English if the device's first language is English, Ukrainian otherwise. Dates and numbers format in the chosen language. `LocalizationTests` fails on missing keys or translations. | `core/i18n.js` | App + all modules | S |
| 0.6 ✅ | **App shell, iOS 26 native**: 4 standard tabs, **Journal · Beans · Devices · Profile**, with no custom center tab. The **Brew action** is an accent **Brew** button in the Journal tab's top bar (a prominent Liquid Glass bar button on iOS 26, accent-tinted on iOS 17–18). With `tabBarMinimizeBehavior = .onScrollDown` the tab bar collapses while scrolling, and the top bar keeps Brew reachable. The action opens the brew flow full screen; it hosts the template "New Brew" form until the Phase 2 wizard. Beans and Devices are placeholders until Phase 1; Settings lives in Profile until Phase 4. The Journal tab reuses the template brew list until 3.1. New **UI test target** `CoffeeMasterUITests` checks the tabs, the Brew action and collapse-on-scroll. | `index.html` nav, `core/router.js` | `AppRouter`, flows | S |
| 0.7 ✅ | **Deep link map v1**: `journal`, `journal/<brewId>`, `brew/new`, `beans`, `beans/<id>`, `devices`, `profile`, `profile/achievements`, `settings`, `settings/about`, `settings/design-system` (Debug). Works over both the custom scheme and universal links, paths case-insensitive. The old `brews…` paths are still accepted as aliases. Links to features that don't exist yet land on their tab's root (bean detail → Beans, achievements → Profile). Home Screen quick action → `brew/new`. Tests: parser round-trips plus `DeepLinkUITests`, which opens each link in the app. | — | `DeepLinks` | S |

**Milestone M0:** the app launches with real models and empty states, and can import an exported web JSON file and show counts.

---

## Phase 1 — Inventory (prerequisite for brewing)

| Step | What | Web source | Module | Size |
|---|---|---|---|---|
| 1.1 ✅ | **Beans list**: bags with remaining/total grams, progress bar, "running out" state. | `features/beans` | `BeansFeature` | S |
| 1.2 ✅ | **Add/Edit bean**: name, roaster, bag size, roast profile (Auto / Filter / Espresso / Omni), country, farm, process (presets), cupping score (0–100, validated), descriptors. Add opens as a sheet (Cancel, protected from accidental swipes); edit is pushed from the list or `beans/<id>`, with Delete (confirmation). Saving stamps `updatedAt` (the web's `_upd`); a new bag size keeps the amount already used. Roaster and name are remembered, and the reusable `AutocompleteField` (design system) offers them as chips. Tests: view model, matcher, and a `BeanUITests` add → edit → delete run. | `beans/bean-form.html`, `core/autocomplete.js` | `BeansFeature`, `DesignSystem` | M |
| 1.3 ✅ | **Devices catalog**: the web's built-in database (151 devices, generated into `Domain/Catalog/DeviceCatalog.swift`). Category grid (Brewers, Espresso machines, Grinders, Kettles, Accessories) with owned counts. Category screen: My devices (tap to edit, swipe to remove), the catalog with add/remove toggles, system search (name + details), and quick-add for a name the catalog doesn't have. Add/edit sheet (name, type, remove; duplicates rejected). New `DevicesFeature`; `HostingController.installSearch` for the system search bar. Filter packs come in 1.4. Tests: view models (on the real in-memory repository) and `DeviceUITests`. | `features/devices`, `core/data.js` (`DB`, `DB_CATS`) | `DevicesFeature` | M |
| 1.4 ✅ | **Filters stock**: a Filters tile on the Devices grid (pack count, or how many are running low). Filter packs list: remaining of total with a stock bar, Running low (≤ 10) / Empty badges, −/+ to correct the count, swipe to remove. Add/edit sheet (name, pack size with the web's presets 25…350, what's left when editing, remove), opened at full height. Brews will use filters automatically in 2.7. Tests: view models and `FilterPackUITests`. | `devices/filters.js` | `DevicesFeature` | S |

---

## Phase 2 — Brew wizard (core of the app)

| Step | What | Web source | Module | Size |
|---|---|---|---|---|
| 2.1 ✅ | **Method pick**: Alternative → V60, AeroPress, Chemex, French Press, Drip, Cold Brew, Batch Brewing. Espresso → Espresso, Cappuccino, Flat White, Latte, Bumble, Espresso Tonic. Done: new `BrewFeature`; the Brew action opens step 1 (two group cards, Cancel), a group pushes its methods as a grid, and a method pushes the template brew form with that method preselected until setup (2.2) replaces it. Tests: view model, group lists vs the web, icons exist, `BrewUITests`. | `brew/method`, `setup.js` (`ALT_SUBS` / `ESP_SUBS`) | `BrewFeature` | S |
| 2.2 ✅ | **Setup (alternative)**: pick bean / dripper / filter / grinder (inline add), grinder clicks, temperature, dose, ratio, number of pours, wet filter, AeroPress inverted and filter count. Live calculation (`bCalc`), ratio validation, dripper art. Done: `Domain.BrewSetup` (web defaults and limits, water / bloom, `makeBrew`) and `DripperKind` (the web's name rules: which drippers a method offers). Setup screen in `BrewFeature`; one picker sheet for all four rows lists what you own with stock, offers catalog models when you own no fitting device (tap adds and picks), and "+" pushes the existing Beans / Devices add forms into the sheet (composed by `BrewFlow`). Drip hides brewer and filter; AeroPress adds position and filter count; Cold Brew uses 10–30 °C. Dripper art ported to `Canvas` (cone, origami, flower, AeroPress) in theme colors. Until 2.3, Start continues to the template brew form, prefilled and saving the setup's gear; espresso drinks skip setup until 2.5. **Prefill** (`Domain.BrewSetupDraft`): the last setup per method is remembered on Start (`BrewSetupHistory`, UserDefaults) and restores the recipe and brewer; the bag is the last one used for this kind of brew, else the only bag that fits the roast (filter / espresso; Omni and Auto fit both), else the only bag; the brewer is one you own that fits the method; the filter pack the last or only one with filters; the grinder the last or the one you own. Espresso drinks get the bag prefilled in the template form. **Filter shape** (`FilterPack.shape`: V60 cone, Kalita Wave, Chemex, AeroPress, batch basket; unset = any, so older and imported packs keep working): set on the filter pack form, shown on the list, preselected when adding from a brew; the brew picker lists packs for this brewer first and the rest under "For other brewers", and prefill only picks fitting packs. Tests: Domain rules, setup and picker view models, UserDefaults history, `BrewUITests`. | `brew/setup`, `brew/pickers` | `BrewFeature` | L |
| 2.3 ✅ | **Active brew (pour-over timer)**: main timer + phase timer, pour/pause actions, per-pour target hints, live paused state, AeroPress press, editing poured ml, steps log. Survives backgrounding (timestamps, not intervals). Done: `Domain.PourOverSession` (timestamps only: pour → pause → stir / swirl / shake, 15 s each, auto-stop → … → stop; AeroPress press finishes the brew; pauses under 0.3 s aren't logged; planned pours: bloom ~25 % then equal pours; next-pour marks; live ratio above plan; pause ring 60 s for V60 / Chemex / AeroPress, 30 s otherwise). Active screen in `BrewFeature`; an untyped pour is logged as 0 ml like the web app (the field shows the target). Back asks before discarding a started brew. Until 2.7, Stop replaces the timer with the template brew form, prefilled with the time, poured water and steps (saved with the brew). Tests: session rules incl. backgrounding, view model with a test clock, form prefill, `BrewUITests`. | `brew/active/active.js` | `BrewFeature` | L |
| 2.4 ✅ | **Live Activity: brew timer** on the Lock Screen / Dynamic Island, showing the current phase and the next pour target. Adds the Widget Extension target (see `README.md`). Done: `CoffeeMasterWidgets` extension target (embedded, links `ExtensionModules`); `BrewTimerStatus` (Domain) as the activity's state: title, phase (localized by the app), clocks from start dates (tick on their own), water poured, next pour target (`PourOverSession.nextPourTarget`: bloom, then the next mark). Lock Screen: title + total time, phase + its clock + "→ 160 ml", progress. Dynamic Island: phase icon + clock (compact), phase / clock / title / target / progress (expanded). Driven by the pour-over timer (updates on each phase, ends on Stop / discard, back after a restore); tap opens the brew in progress. The template "Start Brew Timer" on the brew detail is removed. Espresso shots don't get one yet. Tests: next target, the statuses sent per phase, end on Stop / discard, restore; `BrewUITests` checks the Dynamic Island on the Home Screen. | — | `WidgetsShared`, `CoffeeMasterWidgets` | M |
| 2.5 ✅ | **Espresso flow**: machine + accessories, target dose/yield/ratio, shot timer, actual yield; milk / ice / tonic step with frother selection; result. Done: `Domain.EspressoSetup` (web defaults: 18 g, 1:2, 93 °C, 9 bar, 27 s target; milk for Cappuccino / Flat White / Latte, ice for Bumble / Espresso Tonic; `makeBrew` with the actual ratio when weighed) and `EspressoDraft` (prefill: espresso-roast bag, machine / grinder / accessories used last or owned, last recipe remembered in `BrewSetupHistory`). Four screens sharing one view model: setup (gear picker gains espresso machines, accessory chips) → shot timer (timestamps) → milk (autocomplete, frother: steam wand or an accessory) or ice & mixer → result (shot time, actual yield, TDS, rating, notes) → saved with a toast; milk and mixer are remembered for autocomplete. `IceInfo.amountGrams` renamed `cubes` (stored key kept). Deducting the bag, XP and flavors come with 2.6 / 2.7. Tests: Domain rules, view model with a test clock, history storage, `BrewUITests`. | `brew/espresso` | `BrewFeature` | L |
| 2.6 ✅ | **Flavor wheel** (stand-alone component): category wheel → drill-down → selected descriptors, plus aroma buttons. Port the SVG wheel to SwiftUI `Canvas` / `Path` with hit-testing. Done: new `FlavorWheel` module (Core, shared). Taxonomy generated from the web's `flavor-data.js` by `ios/scripts/generate_flavor_taxonomy.py`: the Counter Culture Taster's Flavor Wheel (2020; checked term by term, English names aligned, Lemongrass added) plus, from the SCA / WCR wheel (2016), a Sour · Fermented family and Pomegranate, Chamomile, Ashy, Hay: 11 categories, 136 notes, UA / EN. Ukrainian names are the saved keys and stay unchanged. The SCA "Other" family (papery, musty, chemical) is left out: those are defects. `FlavorSelection` has the web rules (pick at any level; the deepest pick in a branch replaces the shallower one), saved as Ukrainian names like the web app and read back from either language. `FlavorWheelView`: Flavor / Aroma tabs, search (dims what doesn't match), the drill-down wheel in `Canvas` (passed levels as faded rings, center back button, count badges, picked notes raised), hit-testing by angle and radius, an accessibility element per block, picks as removable chips, Reset. Used in the espresso result and, for pour-over, in the brew form after the timer (with notes) until 2.7's rating screen; flavors and aromas are saved with the brew. The web's cascade (list) mode isn't ported. Tests: taxonomy, label round trip, selection rules, search, layout hit-testing, navigation; `BrewUITests` taps Fruit → Tropical → Mango. | `features/flavor-wheel/*` (~950 lines), `flavor-data.js` | `FlavorWheel` (shared) | L |
| 2.7 ✅ | **Rate & save**: rating slider (0–10), flavors/aroma via the wheel, notes, per-pour corrections. Saving inserts the brew and its log entry, decrements bean grams and filter count (with toasts), and adds XP. Result modal. Done: `BrewRepository.record(_:)` saves a new brew and takes its dose and one filter from stock in the same Core Data transaction (the trash gives them back), returning the bag and pack for warnings. Pour-over Rate & Save screen (replaces the template form, now deleted): time and water, the steps with editable pours (a total spreads evenly, like the web), rating, flavor wheel, notes. Result screen for pour-over and espresso: time, water / yield, rating, descriptors; Go to Journal / Brew Again; toasts when the bag is used up or running low and when filters run low. The brew record is the log (no separate entry). **XP waits for 4.2** (levels and XP don't exist yet). Tests: stock taken and returned, rate view model, `BrewUITests` saves a brew and deletes it again. | `brew/rate`, `brew/save.js`, `brew/result` | `BrewFeature` | M |
| 2.8 ✅ | **Draft / restore**: persist the in-progress brew so an app kill doesn't lose it. The web version is disabled, so this is an improvement: native can do it properly. Done: `BrewInProgress` (BrewFeature) saves the brew after every change from the moment it starts — the pour-over timer (session + typed pour), the rating (corrected steps + tasting), the espresso shot / milk / result — in a `DraftStore` (Domain; UserDefaults in the app). The timer keeps timestamps, so a restored brew's clocks are right. At launch (and after a language change) or on Brew, the wizard reopens at the saved step; drafts older than 12 h are dropped. Cleared when the brew is saved or discarded (Back on a started timer or the rating asks first; Cancel on step 1). Debug launch argument `-discardBrewDraft YES` (UI tests use it by default). Tests: draft rules incl. restored clock and the 12 h limit, UserDefaults store, `BrewUITests` kills the app mid-pour and relaunches. | `brew/draft.js` | `BrewFeature` | S |

**Milestone M2:** a full brew from method pick to saved recipe, with a Live Activity timer.

---

## Phase 3 — Journal

| Step | What | Web source | Module | Size |
|---|---|---|---|---|
| 3.1 ✅ | **Feed**: brews grouped by day ("Today / Yesterday / date"), brew card with tabs (recipe / steps / notes), rating ring, like. Done: `BrewsFeature` renamed `JournalFeature`; the template list replaced by the feed: day sections (plain list, sticky headers "Today · date", "Yesterday · date", then the weekday and date); brew card with the bag, roaster, time, café place, method and brewer, a rating ring and leading bar in the rating color (green from 8, amber from 5, red below; `RatingRing` everywhere), dose / ratio / time (volume for café drinks), Details expanding into Recipe (water, temperature, gear, milk / ice) · Steps (the timer log, or the shot for espresso) · Notes (flavor and aroma tags in their wheel colors, notes); like (a heart, saved as `isLiked`; the web's like counter isn't ported); swipe to delete (trash). Tapping the card's top opens the detail (edit comes with 3.2). New Core module `BrewKit` holds what the wizard and the journal share: `clockText`, `decimal`, `ratioText`, `pourTitle`, step / action / method labels and icons, `BrewStepRow` / `BrewStepList`; `FlavorWheel` gains `FlavorTags`. The web's ring diagram of the steps, compare and share buttons aren't ported here (compare 3.5, share 6.1). Tests: day grouping, like, delete, BrewKit text, flavor colors; `BrewUITests` checks the saved brew's card (Today, details, notes, like) and deletes it. | `features/feed` (`feed.js`, `brew-card.js`) | `JournalFeature` | M |
| 3.2 ✅ | **Brew detail & edit**: edit all fields, edit/add/remove steps. Done: tapping a card (or a `journal/<id>` link) opens the brew as a form (it replaces the read-only detail; the card's Details already show it): method and bag, date & time, dose, ratio (espresso: yield and shot time), temperature (café: volume and place), grinder clicks, the steps (pour / pause, ml, seconds; actions keep their name; swipe to remove, Add Step, total below), the rating, flavor wheel and notes (`TastingSections`, moved to `BrewKit` and shared with the wizard), Save Changes ("Brew updated") and Delete. `Brew.edited()` (Domain) is the web's `saveEditBrew`: steps run back to back and give the total time, an espresso's time is its shot and its ratio follows the yield, notes trimmed; `Brew.tasting` reads and writes the rating, flavors, aromas and notes. The bag and gear aren't editable (the pickers live in the wizard; they come with the manual log, 3.3), and stock isn't adjusted when the dose changes. Tests: edit rules, form view model; `BrewUITests` edits the saved brew's dose. | `features/edit-brew` | `JournalFeature` | M |
| 3.3 | **Manual log**: add a brew after the fact (home or café visit), date picker. | `features/log-brew` | `JournalFeature` | M |
| 3.4 | **Delete, undo, trash**: swipe to delete, undo toast, trash screen with restore / permanent delete, automatic purge after the TTL. | `features/trash` | `JournalFeature` | S |
| 3.5 | **Compare**: select 2+ brews (multi-select mode plus a floating button), pour timelines, parameters table, rings, extraction curve, lists. Charts via Swift Charts. | `features/compare` (357 lines) | `CompareFeature` | L |

---

## Phase 4 — Profile, stats, gamification

| Step | What | Web source | Module | Size |
|---|---|---|---|---|
| 4.1 | **Profile + Settings**: name, location, category, experience, avatar (emoji + color picker), language, import web data (D2). | `features/profile`, `profile/settings.html`, `features/avatar-picker` | `ProfileFeature` | M |
| 4.2 | **XP & levels**: computed XP (brews + achievements), 10 tiers (Зернятко → Легенда), level progress, XP history list. | `profile/xp.js`, `features/xp-history` | `Gamification` (Domain logic) + `ProfileFeature` | M |
| 4.3 | **Achievements**: 19 badges (brew_1…500, streak_7…365, pack_1…10, espresso_10/100, filter_50, dev_1…10, avg_8/9); unlock check after save; unlock celebration. | `features/achievements` | `Gamification` | M |
| 4.4 | **Streak & calendar**: daily streak, record, month calendar with brew days. | `features/streak-calendar` | `ProfileFeature` | M |
| 4.5 | **Stats**: periods (week / month / custom), totals, drinks breakdown, profile stats carousel. | `features/stats`, `profile/stats-carousel.js`, `profile/profile-stats.js` | `StatsFeature` | M |
| 4.6 | **Coffee stats**: consumption by period with navigation, weighted charts (Swift Charts). | `features/coffee-stats` | `StatsFeature` | M |

---

## Phase 5 — Accounts & sync (gate for beta)

| Step | What | Web source | Size |
|---|---|---|---|
| 5.1 | **API contract** with the backend team (OpenAPI): auth endpoints, per-entity CRUD for brews / beans / devices / filters / profile, `GET /changes?since=` for delta sync, achievements and XP either computed on the server or synced as records. | — | M |
| 5.2 | **Networking layer on Alamofire** (decided): `APIClient` (async/await over Alamofire `Session`, typed endpoints, `Decodable` responses, error mapping), a `RequestInterceptor` that attaches tokens and refreshes them on 401 (Alamofire `AuthenticationInterceptor`), retry policy, `EventMonitor` logging, environments (dev/stage/prod via xcconfig). New module `Networking`; `APIClient` registered with Factory and mocked in tests. | — | M |
| 5.3 | **Sign in with Apple**: `ASAuthorizationAppleIDButton` on a welcome screen, nonce, identity token → backend → app tokens in the Keychain. Restore the session on launch, sign out, check credential state (`getCredentialState`) on foreground. **Account deletion** in Settings (required by App Store rules). New module `AuthFeature`, gating `AppRouter` (a pending deep link resumes after login). | — | M |
| 5.4 | **Sync engine**: push local changes (outbox), pull with `since`, last-write-wins on `updatedAt`, propagate soft deletes (ties into trash 3.4), first-login merge of local data into the account. Unit tests with fixtures. | — | L |
| 5.5 | Offline-first behavior, a sync status indicator, retry/backoff, background refresh (`BGAppRefreshTask`). | — | S |

**Milestone M5 = TestFlight beta**: feature parity for the daily-use features, with accounts and multi-device sync on our backend.

---

## Phase 6 — Sharing

| Step | What | Web source | Size |
|---|---|---|---|
| 6.1 | **Recipe share cards** (2 images) via `ImageRenderer` + `ShareLink`, replacing html2canvas. | `features/share` | M |
| 6.2 | Share stats and comparisons as images. | `coffee-stats.js` (`cwShareStats`), `compare.js` (`cpShare`), `stats-carousel.js` | S |
| 6.3 | Universal links for shared recipes (`/r/<id>`) once there's a backend endpoint. | — | M |

---

## Phase 7 — Market & community

| Step | What | Web source | Size |
|---|---|---|---|
| 7.1 | **Market**: coffee catalog (currently hard-coded, 19 items: Penyora, Wonder&Full), filters, expandable cards, cart, "add to inventory". Ideally serve the catalog from our backend first. | `features/market` | M |
| 7.2 | **Community**: hidden in the web app ("coming soon"). Ship as a placeholder or skip until there's a backend. | `features/community` | — |

---

## Phase 8 — Native extras (beyond the web app)

| Step | What | Size |
|---|---|---|
| 8.1 | **Home Screen widgets**: streak / today's brews, last recipe (tap → `journal/<id>`), "Brew now" (→ `brew/new`). Data comes from `WidgetSnapshot`. | M |
| 8.2 | **App Intents / Siri / Shortcuts**: "Start a V60 brew", "How many brews this week". Interactive widget buttons. | M |
| 8.3 | Haptics on pours and the timer, keep the screen awake during a brew, metronome/sound cues. | S |
| 8.4 | Notifications: streak reminder, bean running low. | S |
| 8.5 | iPad / landscape layouts, accessibility pass (Dynamic Type, VoiceOver for the wheel and timers). | M |

---

## Review cleanup ✅ (after Phase 0)

A full code review led to one cleanup pass:
- **Bug fixes:** the Haptics setting now works; the widget data refreshes on every brew change; a failed swipe-delete keeps the list; the in-memory repositories match Core Data behavior; the web import file is read off the main thread; the quick action and app name are localized (`InfoPlist.xcstrings`); bags can't have negative grams.
- **Simplifications:** UI code is main-actor by default (Swift tools 6.2); one generic Core Data repository; one shared change broadcaster; `@Lenient` web decoding; standard `Codable` for string-backed types; a single way to start a brew; one button style; a single list of color roles.
- **Removals:** unused router and toast API, leftover code, and a duplicate test.
- **New tests:** brew detail and Settings view model tests, catalog auto-discovery, and a deep-link test for a missing brew.

## Suggested order and parallelism

```
P0 ──► P1 ──► P2 (2.1→2.2→2.3→2.7, then 2.5, 2.4, 2.8)
                 └─ 2.6 Flavor wheel can be built in parallel from P0 onward
       P3 can start after 2.7 (needs saved brews)
       P4 can start after P3.1
       P5 can start after P0 (5.1 API contract can start right away, in parallel with the backend) ── must finish before beta
P6, P7, P8 after beta
```

## Per-step definition of done

- Feature module in `Packages/Sources/Features/<Name>Feature` with a `Module` builder and a `Routing` protocol, wired in a Flow.
- ViewModel unit tests (Swift Testing) and, for data logic, fixture tests against real web JSON.
- Strings in the String Catalog (UA + EN).
- Deep link added if the screen is externally reachable.
- Behavior checked against the web app side by side.
