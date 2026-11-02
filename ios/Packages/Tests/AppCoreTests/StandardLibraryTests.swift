import Testing
@testable import AppCore

struct StandardLibraryTests {
    @Test(arguments: [(-5.0, 1.0), (16, 16), (99, 60)])
    func clampsToRange(_ input: Double, expected: Double) {
        #expect(input.clamped(to: 1...60) == expected)
    }

    @Test func roundsAndTrims() {
        #expect(15.96.roundedToTenth == 16)
        #expect(" Kenya \n".trimmed == "Kenya")
    }

    @Test func listStateFromAFetch() async {
        struct Boom: Error {}
        #expect(await ListState(loading: { [1, 2] }) == .loaded([1, 2]))
        #expect(await ListState<Int>(loading: { [] }) == .empty)
        #expect(await ListState<Int>(loading: { throw Boom() }) != .empty)
    }
}
