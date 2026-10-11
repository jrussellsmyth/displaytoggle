import CoreGraphics
import Foundation

@MainActor
public protocol DisplayManaging: AnyObject {
    var displays: [DisplayInfo] { get }
    var mainDisplay: DisplayInfo? { get }
    @discardableResult
    func refreshDisplays() -> [DisplayInfo]
    func setMainDisplay(id: CGDirectDisplayID) throws
    func toggleMainDisplay() throws
}
