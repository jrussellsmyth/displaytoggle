import CoreGraphics
@testable import DisplayToggleCore
import Testing

@Suite("DisplayManager Production Logic Tests")
@MainActor
struct DisplayManagerTests {
    @Test("toggleMainDisplay alternates between 2 displays using production DisplayManager")
    func testToggleBetweenTwoDisplaysUsingProductionManager() throws {
        var currentDisplays = [
            DisplayInfo(id: 1, name: "D1", bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), isMain: true, isBuiltin: true),
            DisplayInfo(id: 2, name: "D2", bounds: CGRect(x: 1920, y: 0, width: 1920, height: 1080), isMain: false, isBuiltin: false)
        ]

        var appliedOrigins: [CGDirectDisplayID: CGPoint] = [:]
        let manager = DisplayManager(
            displayProvider: { currentDisplays },
            displayReconfigurer: { newOrigins in
                appliedOrigins = newOrigins
                currentDisplays = currentDisplays.map { display in
                    let newOrigin = newOrigins[display.id] ?? display.bounds.origin
                    return DisplayInfo(
                        id: display.id,
                        name: display.name,
                        bounds: CGRect(origin: newOrigin, size: display.bounds.size),
                        isMain: display.id == 2,
                        isBuiltin: display.isBuiltin
                    )
                }
            }
        )

        #expect(manager.mainDisplay?.id == 1)

        try manager.toggleMainDisplay()
        #expect(manager.mainDisplay?.id == 2)
        #expect(appliedOrigins[2] == CGPoint(x: 0, y: 0))
        #expect(appliedOrigins[1] == CGPoint(x: -1920, y: 0))
    }

    @Test("toggleMainDisplay throws when display count is 1 or 3")
    func testToggleFailsWithOneOrThreeDisplays() {
        let d1 = DisplayInfo(id: 1, name: "D1", bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), isMain: true, isBuiltin: true)
        let manager1 = DisplayManager(displayProvider: { [d1] })

        #expect(throws: DisplayError.insufficientDisplays) {
            try manager1.toggleMainDisplay()
        }

        let d2 = DisplayInfo(id: 2, name: "D2", bounds: CGRect(x: 1920, y: 0, width: 1920, height: 1080), isMain: false, isBuiltin: false)
        let d3 = DisplayInfo(id: 3, name: "D3", bounds: CGRect(x: 3840, y: 0, width: 1920, height: 1080), isMain: false, isBuiltin: false)
        let manager3 = DisplayManager(displayProvider: { [d1, d2, d3] })

        #expect(throws: DisplayError.insufficientDisplays) {
            try manager3.toggleMainDisplay()
        }
    }

    @Test("Failed refresh clears displays cache")
    func testFailedRefreshClearsDisplays() {
        final class StateBox: @unchecked Sendable {
            var shouldSucceed = true
        }
        let box = StateBox()
        let manager = DisplayManager(displayProvider: {
            if box.shouldSucceed {
                return [DisplayInfo(id: 1, name: "D1", bounds: .zero, isMain: true, isBuiltin: true)]
            } else {
                return []
            }
        })

        #expect(manager.displays.count == 1)
        box.shouldSucceed = false
        _ = manager.refreshDisplays()
        #expect(manager.displays.isEmpty)
    }

    @Test("Live discovery handles headless CI runners gracefully")
    func testLiveDiscoveryGracefulOnHeadlessCI() {
        let displays = DisplayManager.shared.refreshDisplays()
        if !displays.isEmpty {
            #expect(DisplayManager.shared.mainDisplay != nil)
        } else {
            #expect(DisplayManager.shared.mainDisplay == nil)
        }
    }
}
