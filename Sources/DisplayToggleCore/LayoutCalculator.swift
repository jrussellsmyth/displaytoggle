import CoreGraphics
import Foundation

public struct LayoutCalculator: Sendable {
    /// Computes new origin coordinates for all displays such that `targetMainID` is positioned at (0, 0),
    /// while all other displays maintain their exact relative spatial offsets.
    public static func calculateNewOrigins(
        displays: [DisplayInfo],
        targetMainID: CGDirectDisplayID
    ) throws -> [CGDirectDisplayID: CGPoint] {
        guard let targetDisplay = displays.first(where: { $0.id == targetMainID }) else {
            throw DisplayError.displayNotFound(targetMainID)
        }

        let deltaX = -targetDisplay.bounds.origin.x
        let deltaY = -targetDisplay.bounds.origin.y

        var newOrigins: [CGDirectDisplayID: CGPoint] = [:]
        for display in displays {
            newOrigins[display.id] = CGPoint(
                x: display.bounds.origin.x + deltaX,
                y: display.bounds.origin.y + deltaY
            )
        }

        return newOrigins
    }

    /// Determines the target display to switch to when toggling between two displays.
    /// Throws `DisplayError.insufficientDisplays` if display count is not exactly 2.
    public static func nextToggleTarget(displays: [DisplayInfo]) throws -> CGDirectDisplayID {
        guard displays.count == 2 else {
            throw DisplayError.insufficientDisplays
        }
        guard let nonMain = displays.first(where: { !$0.isMain }) else {
            throw DisplayError.insufficientDisplays
        }
        return nonMain.id
    }
}
