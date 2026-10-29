// swift-tools-version: 6.2
import PackageDescription

// Layering (arrows = "depends on"):
//
//   App target ──► Features ──► Navigation ──► DeepLinks ──► AppCore
//        │             │
//        │             └──────► Domain ◄── DataLayer (Core Data) ──► WebImport
//        │             └──────► DesignSystem
//        ├────► WidgetsShared ──► Domain, DeepLinks, AppCore
//        └────► WebImport ──► Domain          (one-time import of the web app's JSON export)
//
// DI: Factory. Each module declares the keys for the protocols it owns (with preview-safe defaults);
// the app target registers real implementations (`Container+App.swift`). View models use `@Injected`.
//
// Features never import each other. Cross-feature navigation goes through the app's flows.
// Modules listed in `ExtensionModules` must stay UIKit-navigation-free so widgets / live activities can link them.

/// Factory's DI library. Import `FactoryKit`, not `Factory`: same library, but `FactoryTesting` is
/// built on `FactoryKit`, and the two have distinct `Container` types.
let factoryKit: Target.Dependency = .product(name: "FactoryKit", package: "Factory")

/// UI modules run on the main actor by default (Swift 6.2), so views, view models, routers and
/// modules need no `@MainActor`. Pure value types used off the main actor are marked `nonisolated`.
let mainActorByDefault: [SwiftSetting] = [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "Packages",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        // Everything the main app links.
        .library(
            name: "AppModules",
            targets: [
                "AppCore", "Domain", "DataLayer", "DesignSystem", "DeepLinks", "Navigation", "WidgetsShared", "WebImport",
                "BrewsFeature", "SettingsFeature", "BeansFeature",
            ]
        ),
        // Lightweight subset for app extensions (Widget Extension, Live Activities).
        .library(
            name: "ExtensionModules",
            targets: ["AppCore", "Domain", "DesignSystem", "DeepLinks", "WidgetsShared"]
        ),
    ],
    dependencies: [
        // DI container: https://github.com/hmlongco/Factory
        .package(url: "https://github.com/hmlongco/Factory.git", from: "2.5.3"),
    ],
    targets: [
        // MARK: Core
        .target(name: "AppCore", dependencies: [factoryKit], path: "Sources/Core/AppCore"),
        .target(name: "Domain", dependencies: [factoryKit], path: "Sources/Core/Domain"),
        .target(name: "DataLayer", dependencies: ["AppCore", "Domain", "WebImport"], path: "Sources/Core/DataLayer"),
        .target(
            name: "DesignSystem",
            dependencies: ["AppCore", factoryKit],
            path: "Sources/Core/DesignSystem",
            resources: [.process("Resources")],
            swiftSettings: mainActorByDefault
        ),
        .target(name: "DeepLinks", dependencies: ["AppCore"], path: "Sources/Core/DeepLinks"),
        .target(
            name: "Navigation",
            dependencies: ["AppCore", "DeepLinks", "DesignSystem", factoryKit],
            path: "Sources/Core/Navigation",
            swiftSettings: mainActorByDefault
        ),
        .target(
            name: "WidgetsShared",
            dependencies: ["AppCore", "Domain", "DeepLinks"],
            path: "Sources/Core/WidgetsShared",
            resources: [.process("Resources")]
        ),
        .target(name: "WebImport", dependencies: ["Domain"], path: "Sources/Core/WebImport"),

        // MARK: Features
        .target(
            name: "BrewsFeature",
            dependencies: ["AppCore", "Domain", "DesignSystem", "Navigation", factoryKit],
            path: "Sources/Features/BrewsFeature",
            resources: [.process("Resources")],
            swiftSettings: mainActorByDefault
        ),
        .target(
            name: "SettingsFeature",
            dependencies: ["AppCore", "DesignSystem", "Navigation", factoryKit],
            path: "Sources/Features/SettingsFeature",
            resources: [.process("Resources")],
            swiftSettings: mainActorByDefault
        ),
        .target(
            name: "BeansFeature",
            dependencies: ["AppCore", "Domain", "DesignSystem", "Navigation", factoryKit],
            path: "Sources/Features/BeansFeature",
            resources: [.process("Resources")],
            swiftSettings: mainActorByDefault
        ),

        // MARK: Tests
        .testTarget(name: "AppCoreTests", dependencies: ["AppCore"]),
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "LocalizationTests"),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem", "AppCore"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer", "Domain", "WebImport"]),
        .testTarget(name: "WebImportTests", dependencies: ["WebImport", "Domain"], resources: [.copy("Fixtures")]),
        .testTarget(name: "DeepLinksTests", dependencies: ["DeepLinks"]),
        .testTarget(
            name: "SettingsFeatureTests",
            dependencies: ["SettingsFeature", "AppCore", factoryKit, .product(name: "FactoryTesting", package: "Factory")]
        ),
        .testTarget(
            name: "BrewsFeatureTests",
            dependencies: ["BrewsFeature", "Domain", factoryKit, .product(name: "FactoryTesting", package: "Factory")]
        ),
        .testTarget(
            name: "BeansFeatureTests",
            dependencies: ["BeansFeature", "Domain", factoryKit, .product(name: "FactoryTesting", package: "Factory")]
        ),
    ]
)
