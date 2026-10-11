import CoreGraphics
import Foundation

public protocol DisplayManaging: AnyObject, Sendable {
    var displays: [DisplayInfo] { get }
    var mainDisplay: DisplayInfo? { get }
    func refreshDisplays() -> [DisplayInfo]
    func setMainDisplay(id: CGDirectDisplayID) throws
    func toggleMainDisplay() throws
}
