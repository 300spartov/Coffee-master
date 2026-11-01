import Foundation
import Testing
@testable import FlavorWheel

struct FlavorTaxonomyTests {
    @Test func matchesTheWebData() {
        let categories = FlavorTaxonomy.categories
        #expect(categories.count == 11)
        #expect(categories.flatMap(\.groups).flatMap(\.notes).count == 136)
        #expect(categories.first?.name == FlavorName("Фрукти", "Fruit"))
        #expect(Set(categories.map(\.id)).count == categories.count)
    }

    /// Counter Culture's wheel (2020) plus the SCA / WCR sour / fermented family. Ukrainian names are
    /// the saved keys and must not change; English names follow the Counter Culture wheel.
    @Test func followsTheReferenceWheels() {
        #expect(FlavorTaxonomy.categories.map(\.id) == ["fruit", "ferment", "choco", "sweet", "nut", "grain", "roast", "spice", "savory", "veg", "floral"])
        #expect(FlavorTaxonomy.path(forLabel: "Lemongrass")?.categoryID == "floral")
        #expect(FlavorTaxonomy.path(forLabel: "Winey") == FlavorPath(category: "ferment", group: "fermented", note: "Винне"))
        #expect(FlavorTaxonomy.path(forLabel: "Grassy")?.note == "Трав’янисте")
        #expect(FlavorTaxonomy.path(forLabel: "Кисле · Ферментоване") == FlavorPath(category: "ferment"))
        // A note named like a group or category ("Ферментоване") stays a note.
        #expect(FlavorTaxonomy.path(forLabel: "Ферментоване")?.level == 3)
    }

    @Test func everySavedLabelFindsItsPlace() {
        for category in FlavorTaxonomy.categories {
            for group in category.groups {
                for note in group.notes {
                    let path = FlavorTaxonomy.path(forLabel: note.uk)
                    #expect(path?.storedLabel == note.uk, "\(note.uk)")
                }
            }
        }
        // English labels (older data) map too; a group named like its category is the category.
        #expect(FlavorTaxonomy.path(forLabel: "Mango")?.note == "Манго")
        #expect(FlavorTaxonomy.path(forLabel: "Тропічні") == FlavorPath(category: "fruit", group: "trop"))
        #expect(FlavorTaxonomy.path(forLabel: "Горіхи") == FlavorPath(category: "nut"))
        #expect(FlavorTaxonomy.path(forLabel: "Unknown") == nil)
    }
}

struct FlavorSelectionTests {
    @Test func deepestPickReplacesTheShallowerOne() {
        var selection = FlavorSelection()
        selection.pick(FlavorPath(category: "fruit"))
        #expect(selection.labels == ["Фрукти"])

        selection.pick(FlavorPath(category: "fruit", group: "trop"))
        #expect(selection.labels == ["Тропічні"])

        selection.pick(FlavorPath(category: "fruit", group: "trop", note: "Манго"))
        selection.pick(FlavorPath(category: "fruit", group: "trop", note: "Ананас"))
        #expect(Set(selection.labels) == ["Манго", "Ананас"])
        #expect(selection.count(under: FlavorPath(category: "fruit")) == 2)

        selection.pick(FlavorPath(category: "fruit", group: "trop", note: "Манго"))
        selection.pick(FlavorPath(category: "fruit", group: "trop", note: "Ананас"))
        #expect(selection.labels == ["Тропічні"])
    }

    @Test func openingAPickedCategoryKeepsItsPicks() {
        var selection = FlavorSelection(labels: ["Манго"])
        selection.pick(FlavorPath(category: "fruit"))
        #expect(selection.labels == ["Манго"])
    }

    @Test func labelsAreInWheelOrderAndRoundTrip() {
        let selection = FlavorSelection(labels: ["Квіти", "Ваніль", "Лимон"])
        #expect(selection.labels == ["Лимон", "Ваніль", "Квіти"])
        #expect(FlavorSelection(labels: selection.labels) == selection)
    }
}

struct FlavorSearchTests {
    @Test func matchesNotesGroupsAndCategoriesInBothLanguages() throws {
        let search = try #require(FlavorSearch("mango"))
        #expect(search.matches(FlavorPath(category: "fruit")))
        #expect(!search.matches(FlavorPath(category: "sweet")))
        #expect(search.matches(FlavorPath(category: "fruit", group: "trop", note: "Манго")))
        #expect(!search.matches(FlavorPath(category: "fruit", group: "trop", note: "Ананас")))
        #expect(try #require(FlavorSearch("ваніль")).matches(FlavorPath(category: "sweet", group: "vanil")))
        #expect(FlavorSearch("  ") == nil)
    }
}

@MainActor
struct WheelLayoutTests {
    @Test func categoriesFillTheRingAndTapsHitThem() {
        let layout = WheelLayout(position: WheelPosition(), selection: FlavorSelection(), search: nil)

        #expect(layout.segments.count == FlavorTaxonomy.categories.count)
        #expect(layout.hubTarget == nil)
        // Just right of 12 o'clock, in the ring: the first category.
        #expect(layout.action(at: CGPoint(x: 10, y: -130)) == .pick(FlavorPath(category: "fruit")))
        // Just left of 12 o'clock: the last one.
        #expect(layout.action(at: CGPoint(x: -10, y: -130)) == .pick(FlavorPath(category: "floral")))
        #expect(layout.action(at: .zero) == nil)
        #expect(layout.action(at: CGPoint(x: 0, y: -178)) == nil)
    }

    @Test func notesLevelHasCrumbsAndLiftedPicks() {
        var selection = FlavorSelection()
        selection.pick(FlavorPath(category: "fruit", group: "trop", note: "Лічі"))
        let layout = WheelLayout(position: WheelPosition(category: "fruit", group: "trop"), selection: selection, search: nil)

        #expect(layout.segments.count == 10)
        #expect(layout.segments.first?.isLifted == true)
        let groups = WheelPosition(category: "fruit")
        #expect(layout.crumbs.map(\.target) == [WheelPosition(), groups])
        #expect(layout.action(at: .zero) == .go(groups))
        #expect(layout.action(at: CGPoint(x: 0, y: -60)) == .go(WheelPosition()))
        #expect(layout.action(at: CGPoint(x: 0, y: -100)) == .go(groups))
    }

    @Test func dimmedSegmentsDontReact() throws {
        let layout = WheelLayout(position: WheelPosition(), selection: FlavorSelection(), search: FlavorSearch("mango"))
        #expect(layout.segments.filter { !$0.isDimmed }.map(\.path) == [FlavorPath(category: "fruit")])
        #expect(layout.action(at: CGPoint(x: -10, y: -130)) == nil)
    }

    @Test func colorShading() {
        #expect(FlavorColor.shade(0x808080, 0) == 0x808080)
        #expect(FlavorColor.shade(0x000000, 1) == 0xffffff)
        #expect(FlavorColor.shade(0xffffff, -1) == 0x000000)
        #expect(FlavorColor.wantsDarkText(0xd99a3a))
        #expect(!FlavorColor.wantsDarkText(0x5a3420))
        // A saved note gets its block's color on the wheel (the journal's tags).
        let mango = try! #require(FlavorTaxonomy.path(forLabel: "Манго"))
        let layout = WheelLayout(position: WheelPosition(category: mango.categoryID, group: mango.groupID), selection: FlavorSelection(), search: nil)
        #expect(layout.segments.first { $0.path == mango }?.color == mango.color)
        #expect(FlavorPath(category: "fruit").color == FlavorTaxonomy.category("fruit")?.color)
    }
}

@MainActor
struct FlavorWheelModelTests {
    @Test func navigationFollowsTheWebApp() {
        let model = FlavorWheelModel(flavors: [], aromas: [])

        // "Nuts" has one group: straight to its notes.
        model.perform(.pick(FlavorPath(category: "nut")))
        #expect(model.position == WheelPosition(category: "nut", group: "nuts"))
        #expect(model.selection.labels == ["Горіхи"])
        #expect(model.layout.hubTarget == WheelPosition())

        model.perform(.go(WheelPosition()))
        model.perform(.pick(FlavorPath(category: "fruit")))
        model.perform(.pick(FlavorPath(category: "fruit", group: "berry")))
        model.perform(.pick(FlavorPath(category: "fruit", group: "berry", note: "Малина")))
        #expect(model.layout.hubTarget == WheelPosition(category: "fruit"))
        #expect(model.flavors.labels.contains("Малина"))
    }

    @Test func tabsKeepSeparatePicks() {
        let model = FlavorWheelModel(flavors: ["Манго"], aromas: [])
        model.tab = .aroma
        model.perform(.pick(FlavorPath(category: "floral")))
        model.perform(.pick(FlavorPath(category: "floral", group: "flowers", note: "Жасмин")))

        #expect(model.flavors.labels == ["Манго"])
        #expect(model.aromas.labels == ["Жасмин"])
        #expect(model.position == WheelPosition(category: "floral", group: "flowers"))
        model.tab = .flavor
        #expect(model.position == WheelPosition())
    }
}
