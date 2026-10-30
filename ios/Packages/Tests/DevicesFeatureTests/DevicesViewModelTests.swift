import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
@testable import DevicesFeature

@MainActor
final class SpyDevicesRouter: DeviceCategoriesRouting, DeviceCatalogRouting, DeviceFormRouting {
    private(set) var shownCategories: [DeviceType] = []
    private(set) var addedTypes: [DeviceType] = []
    private(set) var editedIDs: [Device.ID] = []
    private(set) var finished: [Device?] = []
    private(set) var deletedIDs: [Device.ID] = []
    private(set) var notFoundIDs: [Device.ID] = []
    private(set) var filterPacksShownCount = 0

    func showCategory(_ type: DeviceType) { shownCategories.append(type) }
    func showFilterPacks() { filterPacksShownCount += 1 }
    func showAddDevice(type: DeviceType) { addedTypes.append(type) }
    func showEditDevice(id: Device.ID) { editedIDs.append(id) }
    func deviceFormDidFinish(saved device: Device?) { finished.append(device) }
    func deviceFormDidDelete(id: Device.ID) { deletedIDs.append(id) }
    func deviceFormNotFound(id: Device.ID) { notFoundIDs.append(id) }
}

/// Uses the real in-memory repository, so add / remove / duplicate rules behave as in the app.
@Suite(.container)
@MainActor
struct DeviceCatalogViewModelTests {
    private let router = SpyDevicesRouter()

    private func makeViewModel(_ type: DeviceType = .dripper, devices: [Device] = []) -> (DeviceCatalogViewModel, InMemoryRecordRepository<Device>) {
        let repository = InMemoryRecordRepository(devices: devices)
        Container.shared.deviceRepository.register { repository }
        return (DeviceCatalogViewModel(type: type, router: router), repository)
    }

    @Test func togglingAddsThenRemovesCatalogDevice() async throws {
        let (viewModel, repository) = makeViewModel()
        await viewModel.load()
        let v60 = try #require(DeviceCatalog.devices(of: .dripper).first { $0.name == "Hario V60 02" })

        await viewModel.toggle(v60)
        await viewModel.load()
        #expect(viewModel.isOwned(v60))
        #expect(try await repository.fetchAll().map(\.name) == ["Hario V60 02"])

        await viewModel.toggle(v60)
        await viewModel.load()
        #expect(!viewModel.isOwned(v60))
        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test func showsOnlyThisCategory() async {
        let (viewModel, _) = makeViewModel(.grinder, devices: Device.samples)

        await viewModel.load()

        #expect(viewModel.owned.map(\.name) == ["Comandante C40 MK4"])
        #expect(viewModel.catalogCount == DeviceCatalog.devices(of: .grinder).count)
    }

    @Test func searchFiltersByNameAndDetails() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()

        viewModel.query = "chemex"
        #expect(viewModel.visibleCatalog.map(\.name) == ["Chemex 3-cup", "Chemex 6-cup", "Chemex 8-cup"])

        viewModel.query = "cold brew"
        #expect(viewModel.visibleCatalog.contains { $0.name == "Toddy Cold Brew System" })
    }

    @Test func quickAddOffersUnknownNameOnly() async {
        let (viewModel, _) = makeViewModel(devices: [Device(name: "My Custom Dripper", type: .dripper)])
        await viewModel.load()

        viewModel.query = "  "
        #expect(viewModel.quickAddName == nil)
        viewModel.query = "hario v60 02" // exact catalog name
        #expect(viewModel.quickAddName == nil)
        viewModel.query = "my custom dripper" // already owned
        #expect(viewModel.quickAddName == nil)
        viewModel.query = " Kalita Tsubame "
        #expect(viewModel.quickAddName == "Kalita Tsubame")
    }

    @Test func quickAddSavesTypedName() async throws {
        let (viewModel, repository) = makeViewModel(.kettle)
        await viewModel.load()
        viewModel.query = "Grandma's Kettle"

        await viewModel.quickAdd()

        let saved = try await repository.fetchAll()
        #expect(saved.map(\.name) == ["Grandma's Kettle"])
        #expect(saved.first?.type == .kettle)
    }

    @Test func routes() async {
        let device = Device(name: "Acaia Pearl", type: .accessory)
        let (viewModel, _) = makeViewModel(.accessory, devices: [device])

        viewModel.didTapAdd()
        viewModel.didSelect(device)

        #expect(router.addedTypes == [.accessory])
        #expect(router.editedIDs == [device.id])
    }
}

@Suite(.container)
@MainActor
struct DeviceCategoriesViewModelTests {
    @Test func countsOwnedPerCategory() async {
        Container.shared.deviceRepository.register { InMemoryRecordRepository(devices: Device.samples) }
        let router = SpyDevicesRouter()
        let viewModel = DeviceCategoriesViewModel(router: router)

        await viewModel.load()
        viewModel.didSelect(.kettle)

        #expect(viewModel.ownedCount(.dripper) == 2)
        #expect(viewModel.ownedCount(.grinder) == 1)
        #expect(viewModel.catalogCount(.dripper) == 39)
        #expect(!viewModel.categories.contains(.filter))
        #expect(router.shownCategories == [.kettle])
    }
}

@Suite(.container)
@MainActor
struct DeviceFormViewModelTests {
    private let router = SpyDevicesRouter()

    private func makeViewModel(_ mode: DeviceFormViewModel.Mode, devices: [Device] = []) -> (DeviceFormViewModel, InMemoryRecordRepository<Device>) {
        let repository = InMemoryRecordRepository(devices: devices)
        Container.shared.deviceRepository.register { repository }
        return (DeviceFormViewModel(mode: mode, router: router), repository)
    }

    @Test func addSavesTrimmedNameWithPreselectedType() async throws {
        let (viewModel, repository) = makeViewModel(.add(.grinder))
        #expect(!viewModel.isValid)
        viewModel.name = "  Kingrinder K6 "

        await viewModel.save()

        let saved = try #require(try await repository.fetchAll().first)
        #expect(saved.name == "Kingrinder K6")
        #expect(saved.type == .grinder)
        // The repository stamps `updatedAt` on save, so compare identity, not the whole value.
        #expect(router.finished.map { $0?.id } == [saved.id])
    }

    @Test func duplicateIsRejected() async throws {
        let (viewModel, repository) = makeViewModel(.add(.dripper), devices: [Device(name: "Hario V60 02", type: .dripper)])
        viewModel.name = "hario v60 02"

        await viewModel.save()

        #expect(viewModel.alertMessage == tr("You already have this device."))
        #expect(try await repository.fetchAll().count == 1)
        #expect(router.finished.isEmpty)
    }

    @Test func editCanChangeTypeAndKeepName() async throws {
        let device = Device(name: "Acaia Pearl", type: .accessory)
        let (viewModel, repository) = makeViewModel(.edit(device.id), devices: [device])
        await viewModel.load()
        #expect(viewModel.isEditing)
        #expect(viewModel.name == "Acaia Pearl")

        viewModel.type = .kettle
        await viewModel.save()

        let saved = try await repository.fetch(id: device.id)
        #expect(saved.type == .kettle)
        #expect(router.finished.count == 1)
    }

    @Test func editSavingUnchangedIsNotADuplicate() async {
        let device = Device(name: "Acaia Pearl", type: .accessory)
        let (viewModel, _) = makeViewModel(.edit(device.id), devices: [device])
        await viewModel.load()

        await viewModel.save()

        #expect(viewModel.alertMessage == nil)
        #expect(router.finished.count == 1)
    }

    @Test func deleteAndNotFound() async throws {
        let device = Device(name: "Acaia Pearl", type: .accessory)
        let (viewModel, repository) = makeViewModel(.edit(device.id), devices: [device])
        await viewModel.load()

        await viewModel.delete()
        #expect(router.deletedIDs == [device.id])
        #expect(try await repository.fetchAll().isEmpty)

        let (missing, _) = makeViewModel(.edit(.fixture(404)))
        await missing.load()
        #expect(router.notFoundIDs == [.fixture(404)])
    }
}

struct TestError: LocalizedError {
    var errorDescription: String? { "Boom" }
}

/// Repository whose reads fail, for error states.
struct FailingDeviceRepository: DeviceRepository {
    func fetchAll() async throws -> [Device] { throw TestError() }
    func fetchAll(of type: DeviceType) async throws -> [Device] { throw TestError() }
    func fetch(id: Device.ID) async throws -> Device { throw TestError() }
    func contains(name: String, type: DeviceType) async throws -> Bool { throw TestError() }
    func save(_ record: Device) async throws { throw TestError() }
    func delete(id: Device.ID) async throws { throw TestError() }
    func changes() async -> AsyncStream<Void> { AsyncStream { _ in } }
}

@Suite(.container)
@MainActor
struct DeviceReviewFixesTests {
    private let router = SpyDevicesRouter()

    @Test func doubleTapOnToggleAddsOnce() async throws {
        let repository = InMemoryRecordRepository(devices: [])
        Container.shared.deviceRepository.register { repository }
        let viewModel = DeviceCatalogViewModel(type: .kettle, router: router)
        await viewModel.load()
        let takahiro = try #require(DeviceCatalog.devices(of: .kettle).first { $0.name == "Takahiro" })

        async let first: Void = viewModel.toggle(takahiro)
        async let second: Void = viewModel.toggle(takahiro)
        _ = await (first, second)

        #expect(try await repository.fetchAll().count == 1)
    }

    @Test func toggleOffRemovesDuplicates() async throws {
        let repository = InMemoryRecordRepository(devices: [
            Device(name: "Takahiro", type: .kettle), Device(name: "takahiro", type: .kettle),
        ])
        Container.shared.deviceRepository.register { repository }
        let viewModel = DeviceCatalogViewModel(type: .kettle, router: router)
        await viewModel.load()
        let takahiro = try #require(DeviceCatalog.devices(of: .kettle).first { $0.name == "Takahiro" })

        await viewModel.toggle(takahiro)

        #expect(try await repository.fetchAll().isEmpty)
        #expect(!viewModel.isOwned(takahiro))
    }

    @Test func quickAddIgnoresAccentVariantsOfCatalogNames() async {
        Container.shared.deviceRepository.register { InMemoryRecordRepository(devices: []) }
        let viewModel = DeviceCatalogViewModel(type: .grinder, router: router)
        await viewModel.load()

        viewModel.query = "Mahlkonig X54"

        #expect(viewModel.quickAddName == nil)
        #expect(viewModel.visibleCatalog.map(\.name) == ["Mahlkönig X54"])
    }

    @Test func formLoadErrorShowsRetryState() async {
        Container.shared.deviceRepository.register { FailingDeviceRepository() }
        let viewModel = DeviceFormViewModel(mode: .edit(.fixture(1)), router: router)

        await viewModel.load()

        #expect(viewModel.state == .failed("Boom"))
    }

    @Test func savingAfterConcurrentDeleteRoutesToNotFound() async throws {
        let device = Device(name: "Acaia Pearl", type: .accessory)
        let repository = InMemoryRecordRepository(devices: [device])
        Container.shared.deviceRepository.register { repository }
        let viewModel = DeviceFormViewModel(mode: .edit(device.id), router: router)
        await viewModel.load()

        try await repository.delete(id: device.id) // removed elsewhere
        viewModel.name = "Acaia Pearl S"
        await viewModel.save()

        #expect(router.notFoundIDs == [device.id])
        #expect(try await repository.fetchAll().isEmpty, "The removed device must not come back")
    }
}
