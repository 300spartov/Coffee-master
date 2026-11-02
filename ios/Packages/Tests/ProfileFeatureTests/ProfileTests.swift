import Foundation
import UIKit
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import ProfileFeature

@MainActor
final class SpyProfileRouter: ProfileRouting, ProfileFormRouting, AvatarPickerRouting {
    private(set) var calls: [String] = []
    func showEditProfile() { calls.append("edit") }
    func showAvatarPicker() { calls.append("avatar") }
    func showTrash() { calls.append("trash") }
    func showSettings() { calls.append("settings") }
    func profileFormDidFinish(saved: Bool) { calls.append(saved ? "saved" : "cancelled") }
    func avatarPickerDidFinish() { calls.append("done") }
}

@Suite(.container)
@MainActor
struct ProfileTests {
    private let profiles = InMemoryProfileRepository(profile: UserProfile(name: "Bohdan", title: "Бариста", experience: "2 роки"))
    private let router = SpyProfileRouter()

    init() {
        let profiles = profiles
        Container.shared.profileRepository.register { profiles }
        Container.shared.brewRepository.register { TestRepository(brews: Brew.samples) }
        Container.shared.beanRepository.register { TestRepository(beans: Bean.samples) }
        Container.shared.deviceRepository.register { TestRepository(devices: Device.samples) }
    }

    @Test func profileShowsWhoYouAreAndWhatYouHave() async {
        let viewModel = ProfileViewModel(router: router)

        await viewModel.load()

        #expect(viewModel.profile.name == "Bohdan")
        #expect(viewModel.subtitle == "Barista · 2 роки")
        #expect(viewModel.counts == .init(brews: Brew.samples.count, beans: Bean.samples.count, devices: Device.samples.count))
        viewModel.didTapAvatar(); viewModel.didTapEdit(); viewModel.didTapTrash(); viewModel.didTapSettings()
        #expect(router.calls == ["avatar", "edit", "trash", "settings"])
    }

    @Test func editSavesTrimmedAndKeepsAnImportedTitle() async throws {
        try await profiles.saveProfile(UserProfile(name: "B", title: "Q-grader"))
        let viewModel = ProfileFormViewModel(router: router)
        await viewModel.load()
        #expect(viewModel.titles.last == "Q-grader")

        viewModel.name = "  Bohdan "
        viewModel.location = " Kyiv"
        viewModel.title = "Профессионал"
        await viewModel.save()

        let saved = try await profiles.profile()
        #expect((saved.name, saved.location, saved.title) == ("Bohdan", "Kyiv", "Профессионал"))
        #expect(router.calls == ["saved"])
    }

    @Test func avatarIsSavedAsYouPick() async throws {
        let viewModel = AvatarPickerViewModel(router: router)
        await viewModel.load()

        await viewModel.pick(emoji: "🦊")
        await viewModel.pick(color: Avatar.colorPresets[2])
        #expect(try await profiles.profile().avatar == Avatar(emoji: "🦊", colorHex: "#151e27"))
        await viewModel.pick(emoji: nil)
        #expect(try await profiles.profile().avatar.emoji == nil)
        #expect(Avatar(colorHex: "#151e27").color == 0x151E27)
        #expect(Avatar(colorHex: "blue").color == nil)
    }

    @Test func photoIsASmallSquareAndAnEmojiReplacesIt() async throws {
        let wide = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 800)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 800))
        }
        let viewModel = AvatarPickerViewModel(router: router)
        await viewModel.load()

        await viewModel.pick(photo: try #require(wide.pngData()))
        let photo = try #require(try await profiles.profile().avatar.photo)
        #expect(UIImage(data: photo)?.size == CGSize(width: 400, height: 400))

        await viewModel.pick(emoji: "🦊")
        #expect(try await profiles.profile().avatar.photo == nil)

        await viewModel.pick(photo: Data("not an image".utf8))
        #expect(viewModel.alertMessage != nil)
        #expect(try await profiles.profile().avatar.photo == nil)
    }

    @Test func anyColorIsShownAtOnceAndSavedAfterAPause() async throws {
        let viewModel = AvatarPickerViewModel(router: router)
        await viewModel.load()

        viewModel.pickCustom(color: "#123456")
        viewModel.pickCustom(color: "#abcdef")
        #expect(viewModel.profile.avatar.colorHex == "#abcdef")
        #expect(viewModel.hasCustomColor)
        #expect(try await profiles.profile().avatar.colorHex == nil)   // not yet saved

        try await Task.sleep(for: .milliseconds(600))
        #expect(try await profiles.profile().avatar.colorHex == "#abcdef")
        #expect(AvatarView.hex(AvatarView.color(0xABCDEF)) == "#abcdef")
    }
}
