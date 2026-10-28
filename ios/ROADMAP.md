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

---

## Phase 0 — Foundation (replace template samples with the real domain)

| Step | What | Web source | iOS | Size |
|---|---|---|---|---|
| 0.1 | **Domain models** matching the web schema: `AppState` (profile, beans, filters, equipment, brews, log, trash, xp, achEarned, roasters, beanNames, milks, juices, id, record), plus `Brew` (alt + espresso fields, steps, flavors, aroma), `Bean`, `Filter`, `Device`, `LogEntry`, `Profile`. Use lenient Codable (all fields optional with defaults). | `core/state.js`, `brew/save.js`, `brew/espresso/espresso.js` | `Domain` | M |
| 0.2 | **Local store (Core Data)**: model defined in the `DataLayer` package; `NSPersistentContainer` in the App Group container (widgets can read it); background contexts behind an actor; **persistent history tracking** for the sync outbox and app↔widget change notifications; each entity carries `updatedAt` / `deletedAt`; mapping between `NSManagedObject` and Domain structs; derived data (log entries, XP) computed, not stored. Includes the **web JSON importer** porting the relevant parts of `_migrateS` (D2). Tests use an in-memory store with hand-written fixtures until a real export is available. | `core/state.js` | `DataLayer` | L |
| 0.2b | **Web app: "Export data" button** (Settings) that downloads or shares `cj_v7` as a `.json` file, so users can move their data to iOS. A small change in `src/features/profile`. | `core/state.js` | web | S |
| 0.3 | **Repositories** on top of the store: `BrewRepository`, `BeanRepository`, `DeviceRepository`, `ProfileRepository`, `TrashRepository`. | — | `Domain` / `DataLayer` | S |
| 0.4 | **Design system v2**: the web's dark/copper palette (`--copper`, `--card-lo`, `--txt*`), typography, cards, chips, segmented controls, a numeric keypad component, toast, empty states. | `core/base.css`, `layout.css`, `overlays.css`, `features/numpad` | `DesignSystem` | M |
| 0.5 | **i18n**: String Catalog with UA/EN, plus a language switch in Settings (in-app override). | `core/i18n.js` | App + all modules | S |
| 0.6 | **App shell** (decided): 4 tabs plus a center **Brew** button, like the web nav (Journal · Beans · ▶ Brew · Devices · Profile). The Brew button presents the brew wizard as a full-screen modal flow. Remove the sample `BrewsFeature` / `SettingsFeature`. | `index.html` nav, `core/router.js` | `AppRouter`, flows | S |
| 0.7 | **Deep link map v1**: `journal`, `journal/<brewId>`, `beans`, `beans/<id>`, `devices`, `brew/new`, `profile`, `profile/achievements`, `settings`. | — | `DeepLinks` | S |

**Milestone M0:** the app launches with real models and empty states, and can import an exported web JSON file and show counts.

---

## Phase 1 — Inventory (prerequisite for brewing)

| Step | What | Web source | Module | Size |
|---|---|---|---|---|
| 1.1 | **Beans list**: bags with remaining/total grams, progress bar, "running out" state. | `features/beans` | `BeansFeature` | S |
| 1.2 | **Add/Edit bean**: name, roaster, weight, roast profile, country, process, farm, score, descriptors. Autocomplete from `roasters` / `beanNames`. Delete. Set `_upd` on every edit (sync relies on it). | `beans/bean-form.html`, `core/autocomplete.js` | `BeansFeature` | M |
| 1.3 | **Devices catalog**: category grid (dripper, espresso, grinder, kettle, filter, accessories) built from the built-in database (`DB`); search; mark as owned; add custom; quick-add. | `features/devices`, `core/data.js` (`DB`, `DB_CATS`) | `DevicesFeature` | M |
| 1.4 | **Filters stock**: filter packs with count, low-stock warning. | `devices/filters.js` | `DevicesFeature` | S |

---

## Phase 2 — Brew wizard (core of the app)

| Step | What | Web source | Module | Size |
|---|---|---|---|---|
| 2.1 | **Method pick**: Alternative → V60, AeroPress, Chemex, French Press, Drip, Cold Brew, Batch Brewing. Espresso → Espresso, Cappuccino, Flat White, Latte, Bumble, Espresso Tonic. | `brew/method`, `setup.js` (`ALT_SUBS` / `ESP_SUBS`) | `BrewFeature` | S |
| 2.2 | **Setup (alternative)**: pick bean / dripper / filter / grinder (inline add), grinder clicks, temperature, dose, ratio, number of pours, wet filter, AeroPress inverted and filter count. Live calculation (`bCalc`), ratio validation, dripper art. | `brew/setup`, `brew/pickers` | `BrewFeature` | L |
| 2.3 | **Active brew (pour-over timer)**: main timer + phase timer, pour/pause actions, per-pour target hints, live paused state, AeroPress press, editing poured ml, steps log. Survives backgrounding (timestamps, not intervals). | `brew/active/active.js` | `BrewFeature` | L |
| 2.4 | **Live Activity: brew timer** on the Lock Screen / Dynamic Island, showing the current phase and the next pour target. Adds the Widget Extension target (see `README.md`). | — | `WidgetsShared`, `CoffeeMasterWidgets` | M |
| 2.5 | **Espresso flow**: machine + accessories, target dose/yield/ratio, shot timer, actual yield; milk / ice / tonic step with frother selection; result. | `brew/espresso` | `BrewFeature` | L |
| 2.6 | **Flavor wheel** (stand-alone component): category wheel → drill-down → selected descriptors, plus aroma buttons. Port the SVG wheel to SwiftUI `Canvas` / `Path` with hit-testing. | `features/flavor-wheel/*` (~950 lines), `flavor-data.js` | `FlavorWheel` (shared) | L |
| 2.7 | **Rate & save**: rating slider (0–10), flavors/aroma via the wheel, notes, per-pour corrections. Saving inserts the brew and its log entry, decrements bean grams and filter count (with toasts), and adds XP. Result modal. | `brew/rate`, `brew/save.js`, `brew/result` | `BrewFeature` | M |
| 2.8 | **Draft / restore**: persist the in-progress brew so an app kill doesn't lose it. The web version is disabled, so this is an improvement: native can do it properly. | `brew/draft.js` | `BrewFeature` | S |

**Milestone M2:** a full brew from method pick to saved recipe, with a Live Activity timer.

---

## Phase 3 — Journal

| Step | What | Web source | Module | Size |
|---|---|---|---|---|
| 3.1 | **Feed**: brews grouped by day ("Today / Yesterday / date"), brew card with tabs (recipe / steps / notes), rating ring, like. | `features/feed` (`feed.js`, `brew-card.js`) | `JournalFeature` | M |
| 3.2 | **Brew detail & edit**: edit all fields, edit/add/remove steps. | `features/edit-brew` | `JournalFeature` | M |
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
| 5.2 | **Networking layer**: `APIClient` (async/await, typed endpoints, error mapping), an auth interceptor that refreshes tokens automatically, environments (dev/stage/prod via xcconfig). New module `Networking`. | — | M |
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
