# macOS Menu Bar Display Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar utility in Swift/AppKit that toggles the primary display with a single click when two displays are active, and provides a dropdown menu for multi-monitor setups.

**Architecture:** Pure Swift Package Manager (SPM) architecture with a decoupled `DisplayToggleCore` library managing CoreGraphics display math and a lightweight `DisplayToggleApp` accessory executable managing the `NSStatusItem` menu bar UI. Full developer collaboration tooling configured for VS Code and Xcode.

**Tech Stack:** Swift 6 / macOS 15 SDK, AppKit (`NSStatusItem`, `NSMenu`), CoreGraphics (`CGConfigureDisplayOrigin`, `CGBeginDisplayConfiguration`), XCTest, VS Code SourceKit-LSP & CodeLLDB.

## Global Constraints
- Target platform: macOS 15 (Sequoia) or newer.
- Package manager: Pure Swift Package Manager (`Package.swift`), zero `.xcodeproj` files.
- Team Git rules: Develop feature/bugfix branches in `.worktrees/`, do not push directly to `main`.
- UI behavior: Exactly 2 displays = left-click immediately toggles; right-click (or 3+ displays) = dropdown menu.
- Coordinate rule: Selected main display must be at `(0, 0)`; relative vector offsets between all displays must be preserved.

---

### Task 1: Project Scaffolding, Developer Environment & Formatting Configuration

**Files:**
- Create: `.gitignore`
- Create: `.swift-format`
- Create: `.vscode/extensions.json`
- Create: `.vscode/settings.json`
- Create: `.vscode/tasks.json`
- Create: `.vscode/launch.json`
- Create: `Package.swift`

**Interfaces:**
- Produces: SPM package layout with `DisplayToggleCore` (library), `DisplayToggleApp` (executable), and `DisplayToggleCoreTests` (testTarget).

- [ ] **Step 1: Create `.gitignore`**

```gitignore
.build/
.swiftpm/
.DS_Store
*.xcodeproj/
*.xcworkspace/
.worktrees/
DerivedData/
```

- [ ] **Step 2: Create `.swift-format` configuration**

```json
{
  "version": 1,
  "indentation": {
    "spaces": 4
  },
  "lineLength": 120,
  "respectsExistingLineBreaks": true
}
```

- [ ] **Step 3: Create `.vscode` configuration files**

`.vscode/extensions.json`:
```json
{
  "recommendations": [
    "swiftlang.swift-vscode",
    "vadimcn.vscode-lldb",
    "github.vscode-pull-request-github"
  ]
}
```

`.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "swift.sourcekit-lsp.serverPath": "/usr/bin/sourcekit-lsp"
}
```

`.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "swift: Build Debug",
      "type": "shell",
      "command": "swift build",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "problemMatcher": "$swift-compile"
    },
    {
      "label": "swift: Run Tests",
      "type": "shell",
      "command": "swift test",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "problemMatcher": "$swift-compile"
    }
  ]
}
```

`.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "lldb",
      "request": "launch",
      "name": "Debug DisplayToggleApp",
      "program": "${workspaceFolder}/.build/debug/DisplayToggleApp",
      "args": [],
      "cwd": "${workspaceFolder}",
      "preLaunchTask": "swift: Build Debug"
    }
  ]
}
```

- [ ] **Step 4: Create `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "displaytoggle",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "DisplayToggleCore", targets: ["DisplayToggleCore"]),
        .executable(name: "DisplayToggleApp", targets: ["DisplayToggleApp"])
    ],
    targets: [
        .target(
            name: "DisplayToggleCore",
            dependencies: []
        ),
        .executableTarget(
            name: "DisplayToggleApp",
            dependencies: ["DisplayToggleCore"]
        ),
        .testTarget(
            name: "DisplayToggleCoreTests",
            dependencies: ["DisplayToggleCore"]
        )
    ]
)
```

- [ ] **Step 5: Verify package structure**

Run: `swift package describe`
Expected: Output showing `DisplayToggleCore`, `DisplayToggleApp`, and `DisplayToggleCoreTests` targets.

- [ ] **Step 6: Commit**

```bash
git add .gitignore .swift-format .vscode/ Package.swift
git commit -m "chore: scaffold project structure, VS Code configs, and Package.swift"
```

---

### Task 2: `DisplayToggleCore` Models & Protocols

**Files:**
- Create: `Sources/DisplayToggleCore/Models/DisplayInfo.swift`
- Create: `Sources/DisplayToggleCore/Models/DisplayError.swift`
- Create: `Sources/DisplayToggleCore/Protocols/DisplayManaging.swift`

**Interfaces:**
- Produces:
  - `struct DisplayInfo: Identifiable, Equatable, Sendable`
  - `enum DisplayError: Error, Equatable, Sendable`
  - `protocol DisplayManaging: AnyObject, Sendable`

- [ ] **Step 1: Create `DisplayInfo.swift`**

```swift
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
```

- [ ] **Step 2: Create `DisplayError.swift`**

```swift
import Foundation

public enum DisplayError: Error, Equatable, Sendable {
    case displayNotFound(CGDirectDisplayID)
    case configurationFailed(Int32)
    case insufficientDisplays
}
```

- [ ] **Step 3: Create `DisplayManaging.swift`**

```swift
import CoreGraphics
import Foundation

public protocol DisplayManaging: AnyObject, Sendable {
    var displays: [DisplayInfo] { get }
    var mainDisplay: DisplayInfo? { get }
    func refreshDisplays() -> [DisplayInfo]
    func setMainDisplay(id: CGDirectDisplayID) throws
    func toggleMainDisplay() throws
}
```

- [ ] **Step 4: Verify target compiles**

Run: `swift build --target DisplayToggleCore`
Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/DisplayToggleCore/Models/ Sources/DisplayToggleCore/Protocols/
git commit -m "feat(core): add DisplayInfo, DisplayError, and DisplayManaging protocol"
```

---

### Task 3: Layout Calculator & Coordinate Translation Math (TDD)

**Files:**
- Create: `Sources/DisplayToggleCore/LayoutCalculator.swift`
- Test: `Tests/DisplayToggleCoreTests/LayoutCalculatorTests.swift`

**Interfaces:**
- Consumes: `DisplayInfo`
- Produces: `struct LayoutCalculator { static func calculateNewOrigins(displays: [DisplayInfo], targetMainID: CGDirectDisplayID) throws -> [CGDirectDisplayID: CGPoint] }`

- [ ] **Step 1: Write the failing tests in `LayoutCalculatorTests.swift`**

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test`
Expected: FAIL with "cannot find 'LayoutCalculator' in scope".

- [ ] **Step 3: Implement `LayoutCalculator.swift`**

```swift
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test`
Expected: PASS (all 4 tests passing).

- [ ] **Step 5: Commit**

```bash
git add Sources/DisplayToggleCore/LayoutCalculator.swift Tests/DisplayToggleCoreTests/LayoutCalculatorTests.swift
git commit -m "feat(core): implement LayoutCalculator with comprehensive unit tests"
```

---

### Task 4: CoreGraphics Display Manager & Reconfiguration

**Files:**
- Create: `Sources/DisplayToggleCore/DisplayManager.swift`
- Test: `Tests/DisplayToggleCoreTests/MockDisplayManagerTests.swift`

**Interfaces:**
- Consumes: `LayoutCalculator`, `DisplayManaging`, `DisplayInfo`, `DisplayError`
- Produces: `final class DisplayManager: DisplayManaging, @unchecked Sendable`

- [ ] **Step 1: Write test for MockDisplayManager behavior**

Create `Tests/DisplayToggleCoreTests/MockDisplayManagerTests.swift`:
```swift
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
```

- [ ] **Step 2: Run test to verify it passes**

Run: `swift test`
Expected: PASS

- [ ] **Step 3: Implement `DisplayManager.swift`**

Create `Sources/DisplayToggleCore/DisplayManager.swift`:
```swift
import AppKit
import CoreGraphics
import Foundation

public final class DisplayManager: DisplayManaging, @unchecked Sendable {
    public static let shared = DisplayManager()

    public private(set) var displays: [DisplayInfo] = []

    public var mainDisplay: DisplayInfo? {
        displays.first(where: { $0.isMain })
    }

    public var onDisplaysChanged: (@Sendable () -> Void)?

    private var reconfigurationCallbackAdded = false

    public init() {
        _ = refreshDisplays()
        setupReconfigurationCallback()
    }

    deinit {
        if reconfigurationCallbackAdded {
            CGDisplayRemoveReconfigurationCallback(reconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
        }
    }

    public func refreshDisplays() -> [DisplayInfo] {
        var displayCount: UInt32 = 0
        var activeDisplays = [CGDirectDisplayID](repeating: 0, count: 16)
        let result = CGGetActiveDisplayList(16, &activeDisplays, &displayCount)

        guard result == .success else {
            return []
        }

        let mainID = CGMainDisplayID()
        let screens = NSScreen.screens

        var newDisplays: [DisplayInfo] = []
        for i in 0..<Int(displayCount) {
            let id = activeDisplays[i]
            let bounds = CGDisplayBounds(id)
            let isMain = (id == mainID)
            let isBuiltin = CGDisplayIsBuiltin(id) != 0

            // Match friendly display name from NSScreen
            let name = screens.first(where: {
                if let screenNumber = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
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
        _ = refreshDisplays()
        guard let target = displays.first(where: { $0.id == id }) else {
            throw DisplayError.displayNotFound(id)
        }
        if target.isMain { return }

        let newOrigins = try LayoutCalculator.calculateNewOrigins(displays: displays, targetMainID: id)

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
        _ = refreshDisplays()
        guard displays.count == 2 else {
            throw DisplayError.insufficientDisplays
        }
        guard let nonMain = displays.first(where: { !$0.isMain }) else { return }
        try setMainDisplay(id: nonMain.id)
    }

    private func setupReconfigurationCallback() {
        let callback: CGDisplayReconfigurationCallBack = { _, flags, userInfo in
            guard let userInfo = userInfo else { return }
            let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()
            if flags.contains(.addFlag) || flags.contains(.removeFlag) || flags.contains(.movedFlag) {
                DispatchQueue.main.async {
                    _ = manager.refreshDisplays()
                    manager.onDisplaysChanged?()
                }
            }
        }
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        if CGDisplayRegisterReconfigurationCallback(callback, selfPtr) == .success {
            reconfigurationCallbackAdded = true
        }
    }

    private var reconfigurationCallback: CGDisplayReconfigurationCallBack {
        return { _, _, _ in }
    }
}
```

- [ ] **Step 4: Verify target builds and tests pass**

Run: `swift test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/DisplayToggleCore/DisplayManager.swift Tests/DisplayToggleCoreTests/MockDisplayManagerTests.swift
git commit -m "feat(core): implement DisplayManager with CoreGraphics reconfiguration"
```

---

### Task 5: Status Bar Controller & Menu Builder (`DisplayToggleApp`)

**Files:**
- Create: `Sources/DisplayToggleApp/MenuBuilder.swift`
- Create: `Sources/DisplayToggleApp/StatusBarController.swift`
- Create: `Sources/DisplayToggleApp/AppDelegate.swift`
- Create: `Sources/DisplayToggleApp/main.swift`

**Interfaces:**
- Consumes: `DisplayToggleCore` (`DisplayManager`, `DisplayInfo`)
- Produces: Executable macOS application with `NSStatusItem`

- [ ] **Step 1: Create `MenuBuilder.swift`**

```swift
import AppKit
import DisplayToggleCore

final class MenuBuilder {
    static func buildMenu(
        displays: [DisplayInfo],
        onSelectDisplay: @escaping (CGDirectDisplayID) -> Void,
        onRefresh: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) -> NSMenu {
        let menu = NSMenu()

        // Section Title
        let titleItem = NSMenuItem(title: "Connected Displays", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // Display list
        for display in displays {
            let resolution = "\(Int(display.bounds.width))×\(Int(display.bounds.height))"
            let itemTitle = "\(display.name) (\(resolution))"
            let item = NSMenuItem(title: itemTitle, action: #selector(MenuActionHandler.displaySelected(_:)), keyEquivalent: "")
            item.state = display.isMain ? .on : .off
            item.representedObject = display.id
            item.target = MenuActionHandler.shared
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Refresh Displays
        let refreshItem = NSMenuItem(title: "Refresh Displays", action: #selector(MenuActionHandler.refreshClicked), keyEquivalent: "r")
        refreshItem.target = MenuActionHandler.shared
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit DisplayToggle", action: #selector(MenuActionHandler.quitClicked), keyEquivalent: "q")
        quitItem.target = MenuActionHandler.shared
        menu.addItem(quitItem)

        // Store closures
        MenuActionHandler.shared.onSelectDisplay = onSelectDisplay
        MenuActionHandler.shared.onRefresh = onRefresh
        MenuActionHandler.shared.onQuit = onQuit

        return menu
    }
}

final class MenuActionHandler: NSObject {
    static let shared = MenuActionHandler()

    var onSelectDisplay: ((CGDirectDisplayID) -> Void)?
    var onRefresh: (() -> Void)?
    var onQuit: (() -> Void)?

    @objc func displaySelected(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? CGDirectDisplayID {
            onSelectDisplay?(id)
        }
    }

    @objc func refreshClicked() {
        onRefresh?()
    }

    @objc func quitClicked() {
        onQuit?()
    }
}
```

- [ ] **Step 2: Create `StatusBarController.swift`**

```swift
import AppKit
import DisplayToggleCore

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let displayManager: DisplayManager

    init(displayManager: DisplayManager = .shared) {
        self.displayManager = displayManager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        setupButton()
        updateUI()

        displayManager.onDisplaysChanged = { [weak self] in
            self?.updateUI()
        }
    }

    private func setupButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleButtonClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleButtonClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        let isRightClick = event.type == .rightMouseUp
        let isOptionClick = event.modifierFlags.contains(.option)

        if isRightClick || isOptionClick {
            showMenu()
            return
        }

        // Left click
        let displays = displayManager.displays
        if displays.count == 2 {
            do {
                try displayManager.toggleMainDisplay()
                updateUI()
            } catch {
                NSLog("Failed to toggle display: \(error)")
                showMenu()
            }
        } else {
            showMenu()
        }
    }

    func showMenu() {
        let menu = MenuBuilder.buildMenu(
            displays: displayManager.displays,
            onSelectDisplay: { [weak self] id in
                try? self?.displayManager.setMainDisplay(id: id)
                self?.updateUI()
            },
            onRefresh: { [weak self] in
                _ = self?.displayManager.refreshDisplays()
                self?.updateUI()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Reset menu to nil after tracking so subsequent clicks fire handleButtonClick
        statusItem.menu = nil
    }

    func updateUI() {
        guard let button = statusItem.button else { return }

        let displays = displayManager.displays
        let main = displayManager.mainDisplay

        let iconName = displays.count > 1 ? "display.2" : "display"
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Display Toggle")

        if let main = main {
            if displays.count == 2, let other = displays.first(where: { !$0.isMain }) {
                button.toolTip = "Main: \(main.name)\nClick to toggle to \(other.name)\nRight-click for menu"
            } else {
                button.toolTip = "Main: \(main.name) (\(displays.count) displays connected)"
            }
        } else {
            button.toolTip = "DisplayToggle"
        }
    }
}
```

- [ ] **Step 3: Create `AppDelegate.swift`**

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory agent (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()
    }
}
```

- [ ] **Step 4: Create `main.swift`**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 5: Verify executable build**

Run: `swift build`
Expected: `Build complete!`

- [ ] **Step 6: Commit**

```bash
git add Sources/DisplayToggleApp/
git commit -m "feat(app): add StatusBarController, MenuBuilder, and AppDelegate for menu bar app"
```

---

### Task 6: End-to-End Verification, Formatting & Documentation

**Files:**
- Create: `README.md`
- Verify: Full suite tests pass, binary starts, code formatted

- [ ] **Step 1: Create `README.md`**

Create `README.md` documenting architecture, VS Code usage, building, running, and shortcuts.

- [ ] **Step 2: Run test suite**

Run: `swift test`
Expected: PASS (all tests passing).

- [ ] **Step 3: Test build in Release mode**

Run: `swift build -c release`
Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README with VS Code setup and usage guide"
```
