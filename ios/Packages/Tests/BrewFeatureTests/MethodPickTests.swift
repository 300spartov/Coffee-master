import Testing
import UIKit
import Domain
@testable import BrewFeature

@MainActor
final class SpyMethodPickRouter: MethodPickRouting {
    private(set) var shownGroups: [MethodGroup] = []
    private(set) var picked: [BrewMethod] = []
    private(set) var cancelCount = 0

    func showMethods(in group: MethodGroup) { shownGroups.append(group) }
    func methodPickDidSelect(_ method: BrewMethod) { picked.append(method) }
    func methodPickDidCancel() { cancelCount += 1 }
}

@MainActor
struct MethodPickViewModelTests {
    private let router = SpyMethodPickRouter()

    @Test func stepOneOffersBothGroupsAndRoutesToMethods() {
        let viewModel = MethodPickViewModel(router: router)

        viewModel.didSelect(group: .espresso)

        #expect(viewModel.groups == [.alternative, .espresso])
        #expect(viewModel.methods.isEmpty)
        #expect(router.shownGroups == [.espresso])
    }

    @Test func stepTwoListsGroupMethodsAndRoutesPick() {
        let viewModel = MethodPickViewModel(group: .alternative, router: router)

        viewModel.didSelect(method: .chemex)

        #expect(viewModel.methods == BrewMethod.alternativePresets)
        #expect(router.picked == [.chemex])
    }

    @Test func cancelRoutes() {
        MethodPickViewModel(router: router).cancel()

        #expect(router.cancelCount == 1)
    }
}

struct MethodGroupTests {
    /// The web app's `ALT_SUBS` / `ESP_SUBS`, in order.
    @Test func groupsMatchWebApp() {
        #expect(MethodGroup.alternative.methods.map(\.rawValue) == ["V60", "Aeropress", "Chemex", "French Press", "Drip", "Cold Brew", "Batch Brewing"])
        #expect(MethodGroup.espresso.methods.map(\.rawValue) == ["Espresso", "Cappuccino", "Flat White", "Latte", "Bumble", "Espresso Tonic"])
    }

    /// Every icon exists in the SF Symbols the app runs with, so no tile is blank. (Checked on the test
    /// runtime; the names were chosen from symbols available since iOS 17.)
    @Test func iconsExist() {
        let names = MethodGroup.allCases.map(\.systemImage) + MethodGroup.allCases.flatMap(\.methods).map(\.systemImage)
        for name in names {
            #expect(UIImage(systemName: name) != nil, "Missing SF Symbol \(name)")
        }
    }
}

struct BrewLocalizationTests {
    @Test func resolvesInBothLanguages() {
        #expect(tr("What’s brewing today?", language: .ukrainian) == "Що сьогодні?")
        #expect(tr("Alternative", language: .english) == "Alternative")
    }
}
