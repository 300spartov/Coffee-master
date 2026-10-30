import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import DevicesFeature

@MainActor
final class SpyFilterPacksRouter: FilterPacksRouting, FilterPackFormRouting {
    private(set) var addShownCount = 0
    private(set) var editedIDs: [FilterPack.ID] = []
    private(set) var finished: [FilterPack?] = []
    private(set) var deletedIDs: [FilterPack.ID] = []
    private(set) var notFoundIDs: [FilterPack.ID] = []

    func showAddFilterPack() { addShownCount += 1 }
    func showEditFilterPack(id: FilterPack.ID) { editedIDs.append(id) }
    func filterPackFormDidFinish(saved pack: FilterPack?) { finished.append(pack) }
    func filterPackFormDidDelete(id: FilterPack.ID) { deletedIDs.append(id) }
    func filterPackFormNotFound(id: FilterPack.ID) { notFoundIDs.append(id) }
}

@Suite(.container)
@MainActor
struct FilterPacksViewModelTests {
    private let router = SpyFilterPacksRouter()

    private func makeViewModel(packs: [FilterPack] = FilterPack.samples) -> (FilterPacksViewModel, InMemoryRecordRepository<FilterPack>) {
        let repository = InMemoryRecordRepository(filterPacks: packs)
        Container.shared.filterPackRepository.register { repository }
        return (FilterPacksViewModel(router: router), repository)
    }

    private func packs(_ viewModel: FilterPacksViewModel) -> [FilterPack] {
        if case .loaded(let packs) = viewModel.state { return packs }
        return []
    }

    @Test func loadShowsPacksOrEmpty() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()
        #expect(Set(packs(viewModel).map(\.id)) == Set(FilterPack.samples.map(\.id)))

        let (empty, _) = makeViewModel(packs: [])
        await empty.load()
        #expect(empty.state == .empty)
    }

    @Test func useAndPutBackStayWithinPack() async throws {
        let pack = FilterPack(name: "Cafec", total: 2, remaining: 1)
        let (viewModel, repository) = makeViewModel(packs: [pack])

        await viewModel.useOne(pack)
        await viewModel.useOne(pack)
        #expect(try await repository.fetch(id: pack.id).remaining == 0)
        #expect(packs(viewModel).first?.isEmpty == true)

        await viewModel.putBackOne(pack)
        await viewModel.putBackOne(pack)
        await viewModel.putBackOne(pack)
        #expect(try await repository.fetch(id: pack.id).remaining == 2)
    }

    @Test func deleteRemovesPack() async throws {
        let (viewModel, repository) = makeViewModel()

        await viewModel.delete([FilterPack.samples[0]])

        #expect(try await repository.fetchAll().map(\.id) == [FilterPack.samples[1].id])
        #expect(packs(viewModel).map(\.id) == [FilterPack.samples[1].id])
    }

    @Test func failedWriteKeepsListAndShowsAlert() async {
        Container.shared.filterPackRepository.register { TestRepository(filterPacks: FilterPack.samples, failing: .writes) }
        let viewModel = FilterPacksViewModel(router: router)
        await viewModel.load()

        await viewModel.useOne(FilterPack.samples[0])

        #expect(viewModel.alertMessage == "Boom")
        #expect(packs(viewModel).count == 2)
    }

    @Test func routes() {
        let (viewModel, _) = makeViewModel()

        viewModel.didTapAdd()
        viewModel.didSelect(FilterPack.samples[1])

        #expect(router.addShownCount == 1)
        #expect(router.editedIDs == [FilterPack.samples[1].id])
    }
}

@Suite(.container)
@MainActor
struct FilterPackFormViewModelTests {
    private let router = SpyFilterPacksRouter()

    private func makeViewModel(_ mode: FilterPackFormViewModel.Mode, packs: [FilterPack] = FilterPack.samples) -> (FilterPackFormViewModel, InMemoryRecordRepository<FilterPack>) {
        let repository = InMemoryRecordRepository(filterPacks: packs)
        Container.shared.filterPackRepository.register { repository }
        return (FilterPackFormViewModel(mode: mode, router: router), repository)
    }

    @Test func addSavesFullPackWithTrimmedName() async throws {
        let (viewModel, repository) = makeViewModel(.add, packs: [])
        #expect(!viewModel.isValid)

        viewModel.name = "  Sibarist Fast  "
        viewModel.selectPreset(50)
        await viewModel.save()

        let saved = try #require(try await repository.fetchAll().first)
        #expect(saved.name == "Sibarist Fast")
        #expect(saved.total == 50)
        #expect(saved.remaining == 50)
        #expect(router.finished.map { $0?.id } == [saved.id])
    }

    @Test func editLoadsAndSavesRemaining() async throws {
        let pack = FilterPack.samples[0]
        let (viewModel, repository) = makeViewModel(.edit(pack.id))
        await viewModel.load()
        #expect(viewModel.state == .ready)
        #expect(viewModel.name == pack.name)
        #expect(viewModel.remaining == 64)

        viewModel.remaining = 30
        await viewModel.save()

        #expect(try await repository.fetch(id: pack.id).remaining == 30)
    }

    @Test func remainingAbovePackSizeIsInvalidAndPresetClampsIt() async {
        let (viewModel, _) = makeViewModel(.edit(FilterPack.samples[0].id))
        await viewModel.load()

        viewModel.remaining = 120
        #expect(!viewModel.isValid)

        viewModel.selectPreset(40)
        #expect(viewModel.remaining == 40)
        #expect(viewModel.isValid)
    }

    @Test func deleteAndNotFound() async throws {
        let pack = FilterPack.samples[1]
        let (viewModel, repository) = makeViewModel(.edit(pack.id))
        await viewModel.load()

        await viewModel.delete()
        #expect(router.deletedIDs == [pack.id])
        #expect(try await repository.fetchAll().map(\.id) == [FilterPack.samples[0].id])

        let missing = UUID()
        let (gone, _) = makeViewModel(.edit(missing))
        await gone.load()
        #expect(router.notFoundIDs == [missing])
    }

    @Test func savingAfterConcurrentDeleteRoutesToNotFound() async throws {
        let pack = FilterPack.samples[0]
        let (viewModel, repository) = makeViewModel(.edit(pack.id))
        await viewModel.load()
        try await repository.delete(id: pack.id)

        viewModel.name = "Renamed"
        await viewModel.save()

        #expect(router.notFoundIDs == [pack.id])
        #expect(try await repository.fetchAll().map(\.id) == [FilterPack.samples[1].id])
    }

    @Test func cancelFinishesWithoutSaving() {
        let (viewModel, _) = makeViewModel(.add)

        viewModel.cancel()

        #expect(router.finished.count == 1)
        #expect(router.finished.first! == nil)
    }
}

@Suite(.container)
@MainActor
struct DeviceCategoriesFilterTileTests {
    @Test func countsPacksAndLowOnes() async {
        Container.shared.deviceRepository.register { InMemoryRecordRepository(devices: []) }
        Container.shared.filterPackRepository.register {
            InMemoryRecordRepository(filterPacks: FilterPack.samples + [FilterPack(name: "Empty", total: 100, remaining: 0)])
        }
        let router = SpyDevicesRouter()
        let viewModel = DeviceCategoriesViewModel(router: router)

        await viewModel.load()
        viewModel.didSelectFilters()

        #expect(viewModel.filterPackCount == 3)
        #expect(viewModel.lowFilterPackCount == 2)
        #expect(router.filterPacksShownCount == 1)
    }
}
