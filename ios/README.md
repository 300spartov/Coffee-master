# Coffee Master — iOS

Native iOS app template: **MVVM + Router**, SwiftUI screens, UIKit navigation, deep links,
modular Swift Package, ready for Widgets and Live Activities.

- iOS 17+, Swift 6 (strict concurrency), Xcode 26
- Open `CoffeeMaster.xcodeproj`, run scheme **CoffeeMaster**. `Cmd+U` runs all package tests.

## Structure

```
ios/
├── CoffeeMaster.xcodeproj        # synchronized folders: new files in CoffeeMaster/ are picked up automatically
├── Config/Info.plist             # URL scheme, scene manifest, NSSupportsLiveActivities, quick actions
├── CoffeeMaster/                 # App target = composition layer (thin)
│   ├── App/                      # AppDelegate, SceneDelegate (entry points)
│   ├── DI/                       # Factory registrations: composition root
│   ├── Navigation/
│   │   ├── AppRouter.swift       # window + tab bar + deep-link dispatch
│   │   └── Flows/                # one Flow per tab; implements feature routing protocols
│   └── Services/                 # app-level glue (e.g. widget-syncing repository decorator)
└── Packages/                     # local SPM package — all reusable code
    ├── Sources/Core/
    │   ├── AppCore/              # constants (scheme, app group), logging
    │   ├── Domain/               # models, repository & service protocols, fixtures
    │   ├── DataLayer/            # Core Data store (model in code), repositories, web import service
    │   ├── DesignSystem/         # tokens + reusable SwiftUI components
    │   ├── DeepLinks/            # DeepLink enum + URL parser (Foundation-only)
    │   ├── Navigation/           # Flow, StackRouter, HostingController (UIKit)
    │   ├── WidgetsShared/        # ActivityAttributes, widget snapshot, ActivityKit service
    │   └── WebImport/            # one-time import of the web app's JSON export → Domain models
    ├── Sources/Features/
    │   ├── BrewsFeature/         # list → detail, new brew (modal)
    │   └── SettingsFeature/      # settings → about
    └── Tests/
```

Dependency rules (enforced by `Package.swift`):

- **Features never import other features.** They import `Domain`, `DesignSystem` and `Navigation` only.
- **Only the app target knows concrete types.** They're registered with Factory in `DI/Container+App.swift`.
- `ExtensionModules` (`AppCore`, `Domain`, `DesignSystem`, `DeepLinks`, `WidgetsShared`) must not need
  UIKit navigation, because widget and Live Activity extensions link them.

## How a screen works

```
SwiftUI View ──user intent──► ViewModel ──navigation intent──► XRouting protocol
     ▲                          │                                  │ (implemented by)
     └──── @Observable state ───┘                                  ▼
                                                             Flow (app target)
                                                                   │
                                                             StackRouter → UINavigationController
```

| Piece | Lives in | Responsibility |
|---|---|---|
| `View` | feature (internal) | Renders state, forwards user actions. No `NavigationStack` / `NavigationLink`. |
| `ViewModel` | feature (internal) | `@MainActor @Observable`. State + logic. Holds its router **weakly**. |
| `XRouting` | feature (public) | Navigation *intents* (`showBrewDetail(id:)`), not mechanics. |
| `XModule` | feature (public) | Builds screens: creates the VM, wraps the view in `HostingController`, sets title and bar buttons. |
| `Flow` | app target | Implements routing protocols, pushes and presents through `StackRouter`, handles deep links for its area. |
| `AppRouter` | app target | Owns the tab bar and flows. Single entry point for all deep links. |

The ownership chain has no retain cycles: `Flow → StackRouter → UINavigationController → HostingController → View → ViewModel ⇢ (weak) Flow`.

## Deep links

Map v1 (`DeepLink` + `DeepLinkParser`). The same paths work for the custom scheme and universal links.

| URL (custom scheme) | Universal link | Destination |
|---|---|---|
| `coffeemaster://journal` | `https://coffeemaster.app/journal` | Journal tab |
| `coffeemaster://journal/<brewId>` | `…/journal/<brewId>` | Brew detail |
| `coffeemaster://brew/new` | `…/brew/new` | Brew action (full-screen brew flow) |
| `coffeemaster://beans` | `…/beans` | Beans tab |
| `coffeemaster://beans/<beanId>` | `…/beans/<beanId>` | Bean detail (Beans tab root until Phase 1) |
| `coffeemaster://devices` | `…/devices` | Devices tab |
| `coffeemaster://profile` | `…/profile` | Profile tab |
| `coffeemaster://profile/achievements` | `…/profile/achievements` | Achievements (Profile root until 4.3) |
| `coffeemaster://settings` | `…/settings` | Settings (in Profile) |
| `coffeemaster://settings/about` | `…/settings/about` | About |
| `coffeemaster://settings/design-system` | `…/settings/design-system` | Design System gallery (Debug only) |

Paths are case-insensitive; ids keep their case. The earlier `brews`, `brews/<id>` and `brews/new` paths are still parsed as aliases, but URLs are always generated in the current form (`DeepLink.url`).

How a link travels: `SceneDelegate` (cold or warm start, universal link, quick action) → `AppRouter.open(url)`
→ `DeepLinkParser` → `DeepLink` → dismiss modals → select the flow where `canHandle` is true → `flow.handle(link)`
rebuilds the stack.

- **Testing on the simulator:** `xcrun simctl openurl booted coffeemaster://journal/<brewId>`. In Debug builds you can also
  pass the launch argument `-deeplink coffeemaster://journal/<brewId>`, from the scheme or from UI tests.
- **Cross-feature navigation** uses the same path. For example, Settings → "Log a New Brew" emits `.newBrew` and
  `AppRouter` routes it.
- **Universal links in production:** add the Associated Domains entitlement `applinks:coffeemaster.app` and host
  `/.well-known/apple-app-site-association` on that domain.

**Adding a route:** add a `DeepLink` case → extend `segments(for:)` and `route(_:)` in `DeepLinkParser` →
handle it in the owning flow's `canHandle` / `handle`. The round-trip tests will catch any mismatch.

## Adding a feature

1. Create `Packages/Sources/Features/<Name>Feature/` containing `<Name>Routing.swift`, `<Name>Module.swift`, and a
   `View` + `ViewModel` per screen.
2. Register the target in `Package.swift` (depends on `Domain`, `DesignSystem`, `Navigation`), add it to the
   `AppModules` product, and add a test target.
3. In the app: create the module in a flow (`FeatureModule()`; services reach view models through Factory). Then either add a
   new `Flow` (for a new tab) to `AppRouter.makeFlows()`, or make an existing flow conform to the new routing protocol.
4. Add any deep links (see above).

## Widgets and Live Activities (prepared, not yet added)

Already in place:

- `WidgetsShared.BrewTimerAttributes` is the `ActivityAttributes` for a brew timer. It includes `deepLinkURL`.
- `WidgetsShared.LiveActivityBrewTimerService` starts and ends activities. It's wired to the **Start Brew Timer** button.
- `WidgetsShared.WidgetSnapshot` / `WidgetSnapshotStore` hold the data widgets read from the App Group. The app
  keeps it current through `WidgetSyncService`, which listens to the brew repository's change stream (every write path).
- `DeepLink.url` is the tap target for widgets and Live Activities. Taps arrive in `SceneDelegate` as URLs.
- `NSSupportsLiveActivities = YES` is already in `Info.plist`.

To turn them on:

1. **File → New → Target → Widget Extension** (check *Include Live Activity*). Name it `CoffeeMasterWidgets`.
2. Extension target → *Frameworks and Libraries* → add `ExtensionModules` from the `Packages` package.
3. Add the **App Groups** capability with `group.com.coffeemaster.app` (`AppConfiguration.appGroupID`) to **both**
   targets.
4. Replace the generated code with configurations that use the shared types:

```swift
import WidgetKit
import SwiftUI
import ActivityKit
import WidgetsShared

struct LatestBrewsProvider: TimelineProvider {
    let store = WidgetSnapshotStore()
    func placeholder(in context: Context) -> Entry { Entry(date: .now, snapshot: .placeholder) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, snapshot: store.load() ?? .placeholder))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: .now, snapshot: store.load() ?? .placeholder)], policy: .never))
    }
    struct Entry: TimelineEntry { let date: Date; let snapshot: WidgetSnapshot }
}

struct LatestBrewsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.latestBrews, provider: LatestBrewsProvider()) { entry in
            // render entry.snapshot.items; tap → .widgetURL(entry.snapshot.items.first?.deepLinkURL)
        }
    }
}

struct BrewTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrewTimerAttributes.self) { context in
            Text(timerInterval: context.state.timerRange, countsDown: true)
                .widgetURL(context.attributes.deepLinkURL)
        } dynamicIsland: { context in
            DynamicIsland { /* expanded regions */ } compactLeading: { Image(systemName: "timer") }
            compactTrailing: { Text(timerInterval: context.state.timerRange, countsDown: true) }
            minimal: { Image(systemName: "timer") }
        }
    }
}
```

## Dependency injection (Factory)

[Factory](https://github.com/hmlongco/Factory) 2.5+. **Import `FactoryKit`, not `Factory`.** The package ships the same library under both names, but `FactoryTesting` is built on `FactoryKit`, so mixing them gives two different `Container` types and test isolation silently stops working.

| What | Where |
|---|---|
| Key for a shared protocol, with a **preview-safe default** | The module that owns the protocol, e.g. `Domain/DI/Container+Domain.swift` → `brewRepository`, `trashRepository`, `beanRepository`, `deviceRepository`, `filterPackRepository`, `profileRepository`, `suggestionsRepository` (defaults: in-memory repositories with fixtures), `DesignSystem/DI` → `toasts` (default: silent) |
| Real implementations | `CoffeeMaster/DI/Container+App.swift` → `autoRegister()` |
| App-only services (store, import, toast center) | Also `Container+App.swift` |

```swift
// ViewModel: services by injection, router by init
@ObservationIgnored @Injected(\.brewRepository) private var repository

// Test (Swift Testing): an isolated container per test
@Suite(.container) struct BrewListViewModelTests {
    @Test func loads() async {
        Container.shared.brewRepository.register { TestRepository(brews: Brew.samples) }
        let viewModel = BrewListViewModel(router: SpyRouter())
        …
    }
}
```

- Under `@Observable`, put `@ObservationIgnored` on `@Injected` properties.
- **Concurrency:** UI modules (Navigation, DesignSystem, features) and the app target run on the main actor by default (Swift 6.2 default isolation), so views, view models, routers and flows need no `@MainActor`. Mark pure value types used off the main actor `nonisolated` (see the theme types).
- Routers are **not** injected. They're passed to `init` and held `weak`, because each screen has its own.
- Previews need no setup, because the defaults resolve to fixtures.
- Feature tests use `TestSupport` (`Packages/Tests/TestSupport`): `TestRepository` is the real in-memory repository plus failure injection (`failing: .everything` / `.writes`) and a log of saved records, and `TestError` ("Boom"). Spy routers stay in each test target.

## App shell

- `AppRouter` owns the `UITabBarController`: **Journal · Beans · Devices · Profile**, one `Flow` per tab.
- **Brew action** (starting a brew is app-wide, not a tab): an accent **Brew** button in the **Journal**'s top bar only (`AppRouter.makeBrewButton()`): `UIBarButtonItem.Style.prominent` on iOS 26, accent-tinted before. On iOS 26 the tab bar minimizes while scrolling (`tabBarMinimizeBehavior = .onScrollDown`), and the top bar keeps Brew reachable. It opens `BrewFlow` full screen. `coffeemaster://brew/new` and Profile → "Log a New Brew" go through the same `AppRouter.startBrew()`.
- **UI tests**: `CoffeeMasterUITests` (part of the CoffeeMaster scheme). It scrolls the Journal for real, asserts the tab bar minimizes while the Brew button stays tappable, and attaches screenshots to the test report.

## Localization (Ukrainian + English)

- Every module with UI text has `Resources/Localizable.xcstrings`, and the app has `CoffeeMaster/Localizable.xcstrings`.
- In code, write English and wrap it: `Text(tr("No brews yet"))`, `tr("Version \(version)")`. Interpolations become `%@` (strings) or `%lld` (integers) in the catalog.
- `tr` looks the key up in **this module's** catalog in the **in-app language** (`LanguageSettings`), not the device language. That keeps all modules consistent and makes the in-app switch possible.
- Add the key with both `en` and `uk` values to the module's catalog. `LocalizationTests` fails if a `tr("…")` key or a translation is missing.
- Format interpolated numbers before passing them in (`let value = rating.formatted(…)`), so keys stay simple.
- Screens get the language's `Locale` through `HostingController`, so dates and numbers format correctly. Changing the language rebuilds all flows (`AppRouter.rebuildForLanguageChange`).
- Debug: launch with `-app.language uk` or `-app.language en`.

## Data layer

- Repositories are Domain protocols. The app gets Core Data implementations from `CoreDataRepositories` (`.brews(_:)`, `.beans(_:)`, …); the types behind it stay internal.
- `CoreDataRecordRepository<Record>` is one generic implementation with conditional conformances per protocol, the same shape as `InMemoryRecordRepository`. Per-type side effects live on the record (`StoredRecord.didSoftDelete` / `didRestore`; for example, trashing a brew returns its coffee to stock).
- Change streams come from one `ChangeBroadcaster` per entity.

## Conventions

- ViewModels are `@MainActor @Observable final class`. Mark dependencies and the router `@ObservationIgnored`, and hold
  the router `weak`.
- Screen state uses the shared enums in `AppCore/ViewState.swift`: `ListState<Item>` for lists (`ListState(items)` picks `.empty` or `.loaded`) and `LoadState` for screens that load one record (forms). Render them with `ListStateView` / `LoadStateView` (spinner, error with Retry, content).
- A failed action over usable content (delete, save) sets the view model's `alertMessage`; the view shows it with `.errorAlert($viewModel.alertMessage)`.
- Forms end with `FormActions` (Save, plus a confirmed Delete / Remove when editing), so every form looks and behaves the same.
- Lists that follow the store: `func start() async { await repository.observe { await self.load() } }`, called from `.task`.
- Async work goes through `async` / `await` from `.task { }`, so it's cancelled automatically when the view disappears.
- **Colors come only from the theme** (`Packages/Sources/Core/DesignSystem/Theme/`):
  - `ColorPalette.swift` lists every color role (backgrounds, text, accent, status, separator, bars).
  - `LightTheme.swift` / `DarkTheme.swift` hold the values as hex. Edit these to restyle the app.
  - Use them as `.foregroundStyle(.theme.textSecondary)`, `Color.theme.surface`, `UIColor.theme.accent`. They switch automatically with light/dark mode.
  - Grouped screens: `.themedGroupedBackground()` on the `List`/`Form`, `.themedRow()` on rows. Plain screens: `.themedBackground()`.
  - UIKit chrome (window tint, nav bar, tab bar) is set by `ThemeAppearance`. On iOS 26 the bars stay Liquid Glass, so `navigationBar` / `tabBar` colors apply on iOS 17–18.
  - To add a color: add a property to `ColorPalette` and give it a value in both themes.
- **Sheets in flows**: hold them in a `ModalSlot` (`modal.present { router.presentStack(…) }`, `modal.close()`). It opens at most one at a time, and `modal.current` / `isPresented` go `nil` / `false` however the sheet went away, including `AppRouter` dismissing it for a deep link without telling the flow. `StackRouter.close()` / `pop()` are safe to call mid-animation; they wait for it to finish.
- **Bar buttons** in module builders: `HostingController.setAddButton(accessibilityLabel:identifier:action:)` for "+", and `setCancelButton(action:)` for modal forms (it also blocks swipe-to-dismiss, so typed details aren't lost).
- **Search**: add the system search bar to a screen with `HostingController.installSearch(placeholder:onChange:)` in the module builder, passing the text to the view model (see `DevicesModule.makeCatalog`).
- **UI components** live in `DesignSystem/Components` (cards, chips, stock bars, rating ring, metrics, number fields, buttons, states, text styles). Browse them in the Debug **Design System gallery** (Settings → Developer, or `coffeemaster://settings/design-system`), and add new components to the gallery too.
- Toasts: flows get `any ToastPresenting` (backed by `ToastCenter`) and call `toasts.show(Toast("…", style: .success))`. View models report outcomes through their router, not by showing toasts.
- **Persistence**: features see repository protocols only. `DataLayer` stores each record as indexed columns plus a JSON payload of the Domain struct (the payload is the source of truth). A new Domain field needs no model change; add a column in `CoreDataModel` only when you need to query by it.
- **Debug launch arguments**: `-deeplink <url>` and `-importWebJSON <path>`. For example `xcrun simctl launch booted com.coffeemaster.app -importWebJSON /tmp/export.json`.
- Previews get the in-memory repositories with fixtures (the DI defaults) and a no-op preview router held by a `shared` instance (view models keep routers weakly).
- Tests use Swift Testing (`import Testing`), with `TestSupport.TestRepository` and a spy router per feature test target.
