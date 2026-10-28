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
│   ├── App/                      # AppDelegate, SceneDelegate (entry points), AppContainer (DI)
│   ├── Navigation/
│   │   ├── AppRouter.swift       # window + tab bar + deep-link dispatch
│   │   └── Flows/                # one Flow per tab; implements feature routing protocols
│   └── Services/                 # app-level glue (e.g. widget-syncing repository decorator)
└── Packages/                     # local SPM package — all reusable code
    ├── Sources/Core/
    │   ├── AppCore/              # constants (scheme, app group), logging
    │   ├── Domain/               # models, repository & service protocols, fixtures
    │   ├── DataLayer/            # repository implementations
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
- **Only the app target knows concrete types.** `AppContainer` wires them up.
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

| URL (custom scheme) | Universal link | Destination |
|---|---|---|
| `coffeemaster://brews` | `https://coffeemaster.app/brews` | Brews tab root |
| `coffeemaster://brews/<id>` | `…/brews/<id>` | Brew detail |
| `coffeemaster://brews/new` | `…/brews/new` | New brew (modal) |
| `coffeemaster://settings` | `…/settings` | Settings tab root |
| `coffeemaster://settings/about` | `…/settings/about` | About |

How a link travels: `SceneDelegate` (cold or warm start, universal link, quick action) → `AppRouter.open(url)`
→ `DeepLinkParser` → `DeepLink` → dismiss modals → select the flow where `canHandle` is true → `flow.handle(link)`
rebuilds the stack.

- **Testing on the simulator:** `xcrun simctl openurl booted coffeemaster://brews/sample-1`. In Debug builds you can also
  pass the launch argument `-deeplink coffeemaster://brews/sample-1`, from the scheme or from UI tests.
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
3. In the app: give `AppContainer` a module property. Then either add a new `Flow` (for a new tab) to
   `AppRouter.makeFlows()`, or make an existing flow conform to the new routing protocol.
4. Add any deep links (see above).

## Widgets and Live Activities (prepared, not yet added)

Already in place:

- `WidgetsShared.BrewTimerAttributes` is the `ActivityAttributes` for a brew timer. It includes `deepLinkURL`.
- `WidgetsShared.LiveActivityBrewTimerService` starts and ends activities. It's wired to the **Start Brew Timer** button.
- `WidgetsShared.WidgetSnapshot` / `WidgetSnapshotStore` hold the data widgets read from the App Group. The app
  keeps it current through `WidgetSyncingBrewRepository`.
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

## Conventions

- ViewModels are `@MainActor @Observable final class`. Mark dependencies and the router `@ObservationIgnored`, and hold
  the router `weak`.
- Express screen state as an `enum State` (`loading / loaded / empty / failed`), rendered with `DesignSystem` state views.
- Async work goes through `async` / `await` from `.task { }`, so it's cancelled automatically when the view disappears.
- Colors: system semantic colors only. The accent is the `AccentColor` asset (amber), used through `.tint` / `Color.accentColor`.
- Toasts: flows get `any ToastPresenting` (backed by `ToastCenter`) and call `toasts.show(Toast("…", style: .success))`. View models report outcomes through their router, not by showing toasts.
- Previews use `PreviewBrewRepository` and `PreviewRouter.shared`.
- Tests use Swift Testing (`import Testing`), with a mock repository and a spy router per feature test target.
