import Factory

// Keys for Domain protocols. Defaults are preview-safe (fixtures / no-ops), so SwiftUI previews
// and package tests work without setup. The app registers real implementations in `autoRegister()`.

public extension Container {
    var brewRepository: Factory<any BrewRepository> {
        self { PreviewBrewRepository() }.singleton
    }

    var brewTimer: Factory<any BrewTimerService> {
        self { NoopBrewTimerService() }.singleton
    }
}
