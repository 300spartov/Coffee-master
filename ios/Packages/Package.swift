// swift-tools-version: 6.0
import PackageDescription

// Layering (arrows = "depends on"):
//
//   App target ──► Features ──► Navigation ──► DeepLinks ──► AppCore
//        │             │
//        │             └──────► Domain ◄── DataLayer
//        │             └──────► DesignSystem
//        ├──► WidgetsShared ──► Domain, DeepLinks, AppCore
//        └──► WebImport ──► Domain          (one-time import of the web app's JSON export)
//
// Features never import each other. Cross-feature navigation goes through the app's flows.
// Modules listed in `ExtensionModules` must stay UIKit-navigation-free so widgets / live activities can link them.

let package = Package(
    name: "Packages",
    platforms: [.iOS(.v17)],
    products: [
        // Everything the main app links.
        .library(
            name: "AppModules",
            targets: [
                "AppCore", "Domain", "DataLayer", "DesignSystem", "DeepLinks", "Navigation", "WidgetsShared", "WebImport",
                "BrewsFeature", "SettingsFeature",
            ]
        ),
        // Lightweight subset for app extensions (Widget Extension, Live Activities).
        .library(
            name: "ExtensionModules",
            targets: ["AppCore", "Domain", "DesignSystem", "DeepLinks", "WidgetsShared"]
        ),
    ],
    targets: [
        // MARK: Core
        .target(name: "AppCore", path: "Sources/Core/AppCore"),
        .target(name: "Domain", dependencies: ["AppCore"], path: "Sources/Core/Domain"),
        .target(name: "DataLayer", dependencies: ["Domain"], path: "Sources/Core/DataLayer"),
        .target(name: "DesignSystem", path: "Sources/Core/DesignSystem"),
        .target(name: "DeepLinks", dependencies: ["AppCore"], path: "Sources/Core/DeepLinks"),
        .target(name: "Navigation", dependencies: ["DeepLinks", "DesignSystem"], path: "Sources/Core/Navigation"),
        .target(name: "WidgetsShared", dependencies: ["AppCore", "Domain", "DeepLinks"], path: "Sources/Core/WidgetsShared"),
        .target(name: "WebImport", dependencies: ["Domain"], path: "Sources/Core/WebImport"),

        // MARK: Features
        .target(
            name: "BrewsFeature",
            dependencies: ["Domain", "DesignSystem", "Navigation"],
            path: "Sources/Features/BrewsFeature"
        ),
        .target(
            name: "SettingsFeature",
            dependencies: ["AppCore", "DesignSystem", "Navigation"],
            path: "Sources/Features/SettingsFeature"
        ),

        // MARK: Tests
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "WebImportTests", dependencies: ["WebImport", "Domain"], resources: [.copy("Fixtures")]),
        .testTarget(name: "DeepLinksTests", dependencies: ["DeepLinks"]),
        .testTarget(name: "BrewsFeatureTests", dependencies: ["BrewsFeature", "Domain"]),
    ]
)
