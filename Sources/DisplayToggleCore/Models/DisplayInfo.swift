import CoreGraphics
import Foundation

public struct DisplayInfo: Identifiable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let bounds: CGRect
    public let isMain: Bool
    public let isBuiltin: Bool

    public init(
        id: CGDirectDisplayID,
        name: String,
        bounds: CGRect,
        isMain: Bool,
        isBuiltin: Bool
    ) {
        self.id = id
        self.name = name
        self.bounds = bounds
        self.isMain = isMain
        self.isBuiltin = isBuiltin
    }
}
