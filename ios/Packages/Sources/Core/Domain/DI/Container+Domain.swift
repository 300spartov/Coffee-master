import FactoryKit

// Keys for Domain protocols. Defaults are preview-safe (fixtures / no-ops), so SwiftUI previews
// and package tests work without setup. The app registers real implementations in `autoRegister()`.

public extension Container {
    var brewRepository: Factory<any BrewRepository> {
        self { PreviewBrewRepository() }.cached
    }

    var brewTimer: Factory<any BrewTimerService> {
        self { NoopBrewTimerService() }.cached
    }
}
