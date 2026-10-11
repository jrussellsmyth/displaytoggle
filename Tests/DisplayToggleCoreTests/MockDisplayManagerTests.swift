import CoreGraphics
@testable import DisplayToggleCore
import Testing

final class MockDisplayManager: DisplayManaging, @unchecked Sendable {
    var displays: [DisplayInfo]
    var mainDisplay: DisplayInfo? {
        displays.first(where: { $0.isMain })
    }

    init(displays: [DisplayInfo]) {
        self.displays = displays
    }

    func refreshDisplays() -> [DisplayInfo] {
        return displays
    }

    func setMainDisplay(id: CGDirectDisplayID) throws {
        let newOrigins = try LayoutCalculator.calculateNewOrigins(displays: displays, targetMainID: id)
        displays = displays.map { display in
            let newOrigin = newOrigins[display.id] ?? display.bounds.origin
            let newBounds = CGRect(origin: newOrigin, size: display.bounds.size)
            return DisplayInfo(
                id: display.id,
                name: display.name,
                bounds: newBounds,
                isMain: display.id == id,
                isBuiltin: display.isBuiltin
            )
        }
    }

    func toggleMainDisplay() throws {
        guard displays.count == 2 else {
            throw DisplayError.insufficientDisplays
        }
        guard let nonMain = displays.first(where: { !$0.isMain }) else { return }
        try setMainDisplay(id: nonMain.id)
    }
}

@Suite("DisplayManager Logic Tests")
struct MockDisplayManagerTests {
    @Test("toggleMainDisplay alternates between 2 displays")
    func testToggleBetweenTwoDisplays() throws {
        let d1 = DisplayInfo(id: 1, name: "D1", bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), isMain: true, isBuiltin: true)
        let d2 = DisplayInfo(id: 2, name: "D2", bounds: CGRect(x: 1920, y: 0, width: 1920, height: 1080), isMain: false, isBuiltin: false)
        let manager = MockDisplayManager(displays: [d1, d2])

        #expect(manager.mainDisplay?.id == 1)

        try manager.toggleMainDisplay()
        #expect(manager.mainDisplay?.id == 2)

        try manager.toggleMainDisplay()
        #expect(manager.mainDisplay?.id == 1)
    }

    @Test("toggleMainDisplay throws if display count != 2")
    func testToggleFailsWithOneOrThreeDisplays() {
        let d1 = DisplayInfo(id: 1, name: "D1", bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), isMain: true, isBuiltin: true)
        let manager = MockDisplayManager(displays: [d1])

        #expect(throws: DisplayError.insufficientDisplays) {
            try manager.toggleMainDisplay()
        }
    }
}
