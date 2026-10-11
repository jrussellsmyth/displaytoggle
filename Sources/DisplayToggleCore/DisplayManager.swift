import AppKit
import CoreGraphics
import Foundation

@MainActor
public final class DisplayManager: DisplayManaging {
    public static let shared = DisplayManager()

    public typealias DisplayProvider = @MainActor () -> [DisplayInfo]
    public typealias DisplayReconfigurer = @MainActor ([CGDirectDisplayID: CGPoint]) throws -> Void

    public private(set) var displays: [DisplayInfo] = []

    public var mainDisplay: DisplayInfo? {
        displays.first(where: { $0.isMain })
    }

    public var onDisplaysChanged: (@MainActor () -> Void)?

    private let customProvider: DisplayProvider?
    private let customReconfigurer: DisplayReconfigurer?
    private var reconfigurationCallbackAdded = false

    public init(
        displayProvider: DisplayProvider? = nil,
        displayReconfigurer: DisplayReconfigurer? = nil
    ) {
        self.customProvider = displayProvider
        self.customReconfigurer = displayReconfigurer
        _ = refreshDisplays()
        if displayProvider == nil && displayReconfigurer == nil {
            setupReconfigurationCallback()
        }
    }

    deinit {
        if reconfigurationCallbackAdded {
            CGDisplayRemoveReconfigurationCallback(Self.displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
        }
    }

    @discardableResult
    public func refreshDisplays() -> [DisplayInfo] {
        if let customProvider = customProvider {
            let fetched = customProvider()
            self.displays = fetched
            return fetched
        }

        var displayCount: UInt32 = 0
        var activeDisplays = [CGDirectDisplayID](repeating: 0, count: 16)
        let result = CGGetActiveDisplayList(16, &activeDisplays, &displayCount)

        guard result == .success else {
            self.displays = []
            return []
        }

        let mainID = CGMainDisplayID()
        let screens = NSScreen.screens

        var newDisplays: [DisplayInfo] = []
        let count = min(Int(displayCount), activeDisplays.count)
        for i in 0..<count {
            let id = activeDisplays[i]
            let bounds = CGDisplayBounds(id)
            let isMain = (id == mainID)
            let isBuiltin = CGDisplayIsBuiltin(id) != 0

            // Match friendly display name from NSScreen
            let name = screens.first(where: { screen in
                if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                    return number.uint32Value == id
                }
                if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                    return screenNumber == id
                }
                return false
            })?.localizedName ?? (isBuiltin ? "Built-in Display" : "External Display \(id)")

            newDisplays.append(DisplayInfo(
                id: id,
                name: name,
                bounds: bounds,
                isMain: isMain,
                isBuiltin: isBuiltin
            ))
        }

        self.displays = newDisplays
        return newDisplays
    }

    public func setMainDisplay(id: CGDirectDisplayID) throws {
        let refreshed = refreshDisplays()
        guard !refreshed.isEmpty else {
            throw DisplayError.insufficientDisplays
        }
        guard let target = displays.first(where: { $0.id == id }) else {
            throw DisplayError.displayNotFound(id)
        }
        if target.isMain { return }

        let newOrigins = try LayoutCalculator.calculateNewOrigins(displays: displays, targetMainID: id)

        if let customReconfigurer = customReconfigurer {
            try customReconfigurer(newOrigins)
            _ = refreshDisplays()
            return
        }

        var configRef: CGDisplayConfigRef?
        let beginResult = CGBeginDisplayConfiguration(&configRef)
        guard beginResult == .success, let config = configRef else {
            throw DisplayError.configurationFailed(beginResult.rawValue)
        }

        for (displayID, origin) in newOrigins {
            let configResult = CGConfigureDisplayOrigin(
                config,
                displayID,
                Int32(origin.x.rounded()),
                Int32(origin.y.rounded())
            )
            if configResult != .success {
                CGCancelDisplayConfiguration(config)
                throw DisplayError.configurationFailed(configResult.rawValue)
            }
        }

        let completeResult = CGCompleteDisplayConfiguration(config, .permanently)
        guard completeResult == .success else {
            throw DisplayError.configurationFailed(completeResult.rawValue)
        }

        _ = refreshDisplays()
    }

    public func toggleMainDisplay() throws {
        let refreshed = refreshDisplays()
        let nextTargetID = try LayoutCalculator.nextToggleTarget(displays: refreshed)
        try setMainDisplay(id: nextTargetID)
    }

    private nonisolated static let displayReconfigurationCallback: CGDisplayReconfigurationCallBack = { _, flags, userInfo in
        guard let userInfo = userInfo else { return }
        guard !flags.contains(.beginConfigurationFlag) else { return }
        let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()
        Task { @MainActor in
            manager.refreshDisplays()
            manager.onDisplaysChanged?()
        }
    }

    private func setupReconfigurationCallback() {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        if CGDisplayRegisterReconfigurationCallback(Self.displayReconfigurationCallback, selfPtr) == .success {
            reconfigurationCallbackAdded = true
        }
    }
}
