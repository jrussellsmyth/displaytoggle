# macOS Menu Bar Display Toggle Tool — Design Specification

## Overview
A lightweight macOS menu bar utility that allows users to quickly toggle which connected display is the "main" display (the display with the macOS menu bar and dock origin `(0, 0)`). 

When two displays are connected, clicking the menu bar icon instantly switches the main display between the two without opening menus. When more than two displays are connected (or upon right-click/Option-click), a dropdown menu allows choosing any display as the main display, along with status info and app controls.

## Goals
- **Instant Two-Display Toggle**: Single left-click toggles the main display when exactly two displays are connected.
- **Multi-Display Support**: Dropdown menu allows explicit selection when 3 or more displays are connected.
- **Zero-Friction Team Collaboration**: Pure Swift Package Manager (SPM) architecture targeting macOS 15 (Sequoia)+, with zero `.xcodeproj` merge conflicts.
- **First-Class VS Code Workflow**: Fully configured for VS Code with official Swift extension, CodeLLDB debugging, tasks, and `swift-format`, while retaining one-command Xcode compatibility (`open Package.swift`).
- **Robust Coordinate Preservation**: Mathematically preserves the exact relative spatial arrangement of all monitors when shifting coordinate origin.

---

## Architecture & Project Structure

The project is structured as a Swift Package with two main targets and one test target:

```text
displaytoggle/
├── .vscode/
│   ├── extensions.json         # Recommended extensions: Swift, CodeLLDB, GitHub PRs
│   ├── launch.json             # VS Code LLDB debug launcher
│   ├── settings.json           # Swift-format on save and sourcekit-lsp config
│   └── tasks.json              # Build and test automation tasks
├── .swift-format               # Apple official swift-format rules
├── .gitignore                  # Git ignore rules for SPM, worktrees, VS Code
├── Package.swift               # SPM package manifest targeting macOS 15
├── Sources/
│   ├── DisplayToggleCore/      # Business logic target (pure Swift + CoreGraphics)
│   │   ├── Models/
│   │   │   ├── DisplayInfo.swift
│   │   │   └── DisplayLayout.swift
│   │   ├── Protocols/
│   │   │   └── DisplayManaging.swift
│   │   ├── DisplayManager.swift
│   │   └── LayoutCalculator.swift
│   └── DisplayToggleApp/       # App executable target (AppKit status bar UI)
│       ├── AppDelegate.swift
│       ├── MenuBuilder.swift
│       ├── StatusBarController.swift
│       └── main.swift
└── Tests/
    └── DisplayToggleCoreTests/
        ├── LayoutCalculatorTests.swift
        └── MockDisplayManagerTests.swift
```

### Target Responsibilities

1. **`DisplayToggleCore`**:
   - Independent library with zero AppKit/UI dependencies.
   - Interfaces directly with macOS `CoreGraphics` APIs (`CGGetActiveDisplayList`, `CGMainDisplayID`, `CGBeginDisplayConfiguration`, `CGConfigureDisplayOrigin`, `CGCompleteDisplayConfiguration`).
   - Implements `LayoutCalculator` for computing translation vectors $(\Delta x, \Delta y)$ such that the target display lands on $(0, 0)$ and all other displays retain their relative offsets.
   - Publishes display status and listens for display hardware change notifications via `CGDisplayRegisterReconfigurationCallback`.

2. **`DisplayToggleApp`**:
   - Standalone executable target configured as an accessory app (`LSUIElement = true`).
   - Instantiates `NSStatusItem` in the system menu bar.
   - Handles mouse click events (`.leftMouseUp`, `.rightMouseUp`).
   - Delegates state changes to `DisplayManager` and renders dropdown menus via `MenuBuilder`.

3. **`DisplayToggleCoreTests`**:
   - Automated unit tests covering all multi-monitor layout translations (horizontal side-by-side, vertical stacked, irregular multi-display matrices).
   - Validates error handling and transaction cancellation semantics.

---

## Detailed Components

### 1. Coordinate Mathematics & Display Reconfiguration

In macOS CoreGraphics:
- The "main display" is strictly defined as the display located at origin `(0, 0)`.
- Given $N$ displays $D_1, D_2, \dots, D_N$ where each display $D_i$ has current bounds origin $(x_i, y_i)$.
- To set display $D_T$ (currently at $(x_T, y_T)$) as the new main display:
  $$\Delta x = -x_T, \quad \Delta y = -y_T$$
  $$\forall i \in \{1, \dots, N\}: \quad (x_i', y_i') = (x_i + \Delta x, y_i + \Delta y)$$
- By definition, $(x_T', y_T') = (x_T - x_T, y_T - y_T) = (0, 0)$, establishing $D_T$ as the main display.
- All pairwise vectors $(x_j' - x_i', y_j' - y_i') = (x_j - x_i, y_j - y_i)$ are preserved identically.

#### Atomic Transaction Execution
```swift
var configRef: CGDisplayConfigRef?
guard CGBeginDisplayConfiguration(&configRef) == .success, let config = configRef else {
    throw DisplayError.configurationFailed
}

for (displayID, newOrigin) in calculatedLayout {
    let err = CGConfigureDisplayOrigin(config, displayID, Int32(newOrigin.x), Int32(newOrigin.y))
    if err != .success {
        CGCancelDisplayConfiguration(config)
        throw DisplayError.configurationFailed
    }
}

let result = CGCompleteDisplayConfiguration(config, .permanently)
guard result == .success else {
    throw DisplayError.configurationFailed
}
```

### 2. Status Bar UI & Event Routing

- **Status Item**: `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)`
- **Icon**: Dynamic SF Symbol:
  - Multi-monitor: `display.2`
  - Single monitor: `display`
- **Click Routing (`StatusBarController`)**:
  - The status item button registers for `[.leftMouseUp, .rightMouseUp]`.
  - On mouse click:
    - If `NSEvent.modifierFlags.contains(.option)` OR `event.type == .rightMouseUp`:
      - Pop up dropdown menu.
    - If `event.type == .leftMouseUp`:
      - If `displayManager.activeDisplays.count == 2`:
        - Identify the other display (the one where `!display.isMain`).
        - Invoke `displayManager.setMainDisplay(id: otherDisplay.id)`.
      - Else (1 display or 3+ displays):
        - Pop up dropdown menu.

### 3. Dropdown Menu Layout
Constructed dynamically on each display configuration change:
- Header / Section: "Connected Displays" (disabled title)
- For each display:
  - Title: Display Name + (resolution, e.g. "3840×2160")
  - State: Checkmark `✓` if currently main display
  - Action: Select to make main
- Separator
- "Refresh Displays"
- "Launch at Login" (toggleable checkmark)
- Separator
- "Quit DisplayToggle" (`Cmd+Q`)

---

## Developer Experience & Team Collaboration

### VS Code Tooling
1. **Swift Extension**: `swiftlang.swift-vscode` provides syntax highlighting, autocomplete, code navigation, and diagnostics via SourceKit-LSP.
2. **CodeLLDB**: `vadimcn.vscode-lldb` enables setting breakpoints and debugging both the core library and the status bar app via `launch.json`.
3. **Tasks**:
   - `swift build`: Compiles all targets.
   - `swift test`: Executes unit tests.
   - `swift-format`: Enforces code formatting across all files.

### Formatting & Git Conventions
- **`.swift-format`**: Checked into git root with standard 4-space indentation and line length rules.
- **Git Worktrees**: In accordance with team rules, all feature branches are developed in worktrees under `.worktrees/`.
- **Merge Conflicts**: Pure SPM ensures no monolithic `.pbxproj` file conflicts. Any team member can open `Package.swift` in Xcode if desired without generating Git noise.

---

## Testing Plan

1. **Unit Tests (`DisplayToggleCoreTests`)**:
   - `testHorizontalDisplaySwap`: Given Display A at `(0, 0)` and Display B at `(1920, 0)`, switching to Display B produces Display B at `(0, 0)` and Display A at `(-1920, 0)`.
   - `testVerticalDisplaySwap`: Given Display A at `(0, 0)` and Display B at `(0, -1080)`, switching to Display B produces Display B at `(0, 0)` and Display A at `(0, 1080)`.
   - `testThreeDisplayTranslation`: Given 3 displays in an L-arrangement, switching any display to main preserves relative pairwise distances.
   - `testSingleDisplayNoOp`: Switching main display when only 1 display is active safely retains `(0, 0)`.
2. **Mock Manager Tests**:
   - Validates that `toggleMainDisplay()` alternates between the two displays when count is 2.
   - Validates that errors from CoreGraphics are properly caught and handled without crashing the application.
