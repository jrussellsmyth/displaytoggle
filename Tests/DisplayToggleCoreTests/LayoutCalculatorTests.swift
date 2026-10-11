import CoreGraphics
@testable import DisplayToggleCore
import Testing

@Suite("LayoutCalculator Tests")
struct LayoutCalculatorTests {
    @Test("Horizontal 2-display swap: Display B at (1920, 0) becomes (0, 0) and Display A shifts to (-1920, 0)")
    func testHorizontalSwap() throws {
        let displayA = DisplayInfo(
            id: 1,
            name: "Built-in",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true,
            isBuiltin: true
        )
        let displayB = DisplayInfo(
            id: 2,
            name: "External",
            bounds: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
            isMain: false,
            isBuiltin: false
        )

        let result = try LayoutCalculator.calculateNewOrigins(
            displays: [displayA, displayB],
            targetMainID: 2
        )

        #expect(result[2] == CGPoint(x: 0, y: 0))
        #expect(result[1] == CGPoint(x: -1920, y: 0))
    }

    @Test("Vertical 2-display swap: Display B at (0, -1440) becomes (0, 0) and Display A shifts to (0, 1440)")
    func testVerticalSwap() throws {
        let displayA = DisplayInfo(
            id: 1,
            name: "Bottom Display",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true,
            isBuiltin: true
        )
        let displayB = DisplayInfo(
            id: 2,
            name: "Top Display",
            bounds: CGRect(x: 0, y: -1440, width: 2560, height: 1440),
            isMain: false,
            isBuiltin: false
        )

        let result = try LayoutCalculator.calculateNewOrigins(
            displays: [displayA, displayB],
            targetMainID: 2
        )

        #expect(result[2] == CGPoint(x: 0, y: 0))
        #expect(result[1] == CGPoint(x: 0, y: 1440))
    }

    @Test("3-display translation preserves relative delta between all displays")
    func testThreeDisplayTranslation() throws {
        let displayA = DisplayInfo(
            id: 1,
            name: "Display 1",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true,
            isBuiltin: true
        )
        let displayB = DisplayInfo(
            id: 2,
            name: "Display 2",
            bounds: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
            isMain: false,
            isBuiltin: false
        )
        let displayC = DisplayInfo(
            id: 3,
            name: "Display 3",
            bounds: CGRect(x: -1920, y: 0, width: 1920, height: 1080),
            isMain: false,
            isBuiltin: false
        )

        let result = try LayoutCalculator.calculateNewOrigins(
            displays: [displayA, displayB, displayC],
            targetMainID: 3
        )

        #expect(result[3] == CGPoint(x: 0, y: 0))
        #expect(result[1] == CGPoint(x: 1920, y: 0))
        #expect(result[2] == CGPoint(x: 3840, y: 0))
    }

    @Test("Throws displayNotFound when target display is missing")
    func testTargetNotFound() {
        let displayA = DisplayInfo(
            id: 1,
            name: "Display 1",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true,
            isBuiltin: true
        )

        #expect(throws: DisplayError.displayNotFound(99)) {
            try LayoutCalculator.calculateNewOrigins(displays: [displayA], targetMainID: 99)
        }
    }
}
