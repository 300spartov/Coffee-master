import FactoryKit

// Keys for Domain protocols. Defaults are in-memory repositories seeded with fixtures, so SwiftUI
// previews and package tests work without setup. The app registers Core Data implementations in
// `autoRegister()` (`CoffeeMaster/DI/Container+App.swift`).

public extension Container {
    var brewRepository: Factory<any BrewRepository> {
        self { self.previewBrewStore() }.cached
    }

    var trashRepository: Factory<any TrashRepository> {
        self { self.previewBrewStore() }.cached
    }

    var beanRepository: Factory<any BeanRepository> {
        self { InMemoryRecordRepository(beans: Bean.samples) }.cached
    }

    var deviceRepository: Factory<any DeviceRepository> {
        self { InMemoryRecordRepository(devices: Device.samples) }.cached
    }

    var filterPackRepository: Factory<any FilterPackRepository> {
        self { InMemoryRecordRepository(filterPacks: FilterPack.samples) }.cached
    }

    var profileRepository: Factory<any ProfileRepository> {
        self { InMemoryProfileRepository(profile: UserProfile(name: "Preview")) }.cached
    }

    var suggestionsRepository: Factory<any SuggestionsRepository> {
        self { InMemorySuggestionsRepository() }.cached
    }

    var brewTimer: Factory<any BrewTimerService> {
        self { NoopBrewTimerService() }.cached
    }
}

extension Container {
    /// Brews and trash share one in-memory store in previews, so deleting shows up in the trash.
    var previewBrewStore: Factory<InMemoryRecordRepository<Brew>> {
        self { InMemoryRecordRepository(brews: Brew.samples) }.cached
    }
}
