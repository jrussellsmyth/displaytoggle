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
}
