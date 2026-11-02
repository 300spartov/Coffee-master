import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import DesignSystem
@testable import JournalFeature

/// Keeps the toasts so a test can tap their action.
@MainActor
final class SpyToasts: ToastPresenting {
    private(set) var shown: [Toast] = []
    func show(_ toast: Toast) { shown.append(toast) }
}

@Suite(.container)
@MainActor
struct TrashTests {
    private let store = InMemoryRecordRepository(brews: Brew.samples)
    private let toasts = SpyToasts()

    init() {
        let store = store, toasts = toasts
        Container.shared.brewRepository.register { store }
        Container.shared.trashRepository.register { store }
        Container.shared.toasts.register { toasts }
    }

    @Test func deleteOffersUndo() async throws {
        try await trashBrew(id: Brew.samples[0].id)
        #expect(try await store.trashedBrews().map(\.id) == [Brew.samples[0].id])

        let undo = try #require(toasts.shown.last?.action)
        undo.handler()
        try await Task.sleep(for: .milliseconds(50))

        #expect(try await store.trashedBrews().isEmpty)
        #expect(try await store.fetchAll().count == Brew.samples.count)
    }

    @Test func restoreDeleteAndEmpty() async throws {
        for brew in Brew.samples { try await store.delete(id: brew.id) }
        let viewModel = TrashViewModel()
        await viewModel.load()
        guard case .loaded(let trashed) = viewModel.state else { Issue.record("Not loaded"); return }
        #expect(trashed.count == 3)

        await viewModel.restore(trashed[0])
        await viewModel.deletePermanently(trashed[1])
        #expect(try await store.trashedBrews().map(\.id) == [trashed[2].id])
        #expect(try await store.fetchAll().map(\.id) == [trashed[0].id])
        #expect(toasts.shown.map(\.message) == ["Brew restored"])

        await viewModel.emptyTrash()
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func daysLeftCountDownTheThirtyDays() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let viewModel = TrashViewModel(clock: { now })
        var brew = Brew.samples[0]

        brew.deletedAt = now
        #expect(viewModel.daysLeft(brew) == 30)
        brew.deletedAt = now.addingTimeInterval(-29.5 * 86_400)
        #expect(viewModel.daysLeft(brew) == 1)
    }
}
