import CoreGraphics
import Foundation

public enum DisplayError: Error, Equatable, Sendable {
    case displayNotFound(CGDirectDisplayID)
    case configurationFailed(Int32)
    case insufficientDisplays
}
