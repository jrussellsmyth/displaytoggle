# DisplayToggle

A lightweight macOS menu bar utility that allows users to quickly toggle which connected display is the "main" display (the display hosting the macOS menu bar and dock with coordinate origin `(0, 0)`).

Built with **Swift 6** and **CoreGraphics** for macOS 15 (Sequoia)+.

---

## Features

- **Instant 2-Display Toggle**: Single left-click on the menu bar icon instantly toggles the primary display role between two connected monitors without displaying any menus.
- **Multi-Display Dropdown (3+ Displays)**: When 3 or more displays are connected, clicking the icon opens a dropdown menu allowing instant selection of any display as the main display.
- **Context Menu (Right-Click / Option-Click)**: Right-clicking or Option-clicking the icon always reveals the full context menu regardless of display count:
  - List of connected displays with friendly names, resolutions, and checkmark `✓` indicating the active main display.
  - **Refresh Displays** (`Cmd+R`): Manually re-scans active displays.
  - **Quit DisplayToggle** (`Cmd+Q`): Quits the background menu bar application.
- **Dynamic Menu Bar Icon & Tooltips**:
  - Displays `display.2` SF Symbol when multiple displays are active; `display` when a single display is connected.
  - Dynamic tooltips display the active main display and target toggle monitor.
- **Rigorous Spatial Preservation**: Mathematically preserves the exact relative spatial arrangement of all monitors (horizontal, vertical, or grid matrices) by translating the entire coordinate plane by $(\Delta x, \Delta y)$ to land the target monitor at $(0, 0)$.
- **Dynamic Hardware Reconfiguration**: Automatically detects displays being plugged in, unplugged, or moved via `CGDisplayRegisterReconfigurationCallback` and updates the menu bar interface.
- **Lightweight Accessory Agent**: Configured with `.accessory` activation policy via `NSApp.setActivationPolicy(.accessory)`, operating silently in the menu bar without cluttering the Dock or Cmd-Tab switcher.

---

## Architecture & Target Breakdown

The project is organized as a pure Swift Package Manager (SPM) workspace:

```text
displaytoggle/
├── .vscode/
│   ├── extensions.json         # Recommended extensions (Swift, CodeLLDB, GitHub PRs)
│   ├── launch.json             # CodeLLDB debug launcher configuration
│   ├── settings.json           # Swift formatOnSave & sourcekit-lsp settings
│   └── tasks.json              # VS Code build and test automation tasks
├── .swift-format               # Apple swift-format configuration
├── .gitignore                  # Git ignore rules for SPM, worktrees, and VS Code
├── Package.swift               # SPM manifest targeting macOS 15
├── Sources/
│   ├── DisplayToggleCore/      # Business logic target (CoreGraphics + AppKit screen naming)
│   │   ├── Models/
│   │   │   ├── DisplayError.swift
│   │   │   └── DisplayInfo.swift
│   │   ├── Protocols/
│   │   │   └── DisplayManaging.swift
│   │   ├── DisplayManager.swift
│   │   └── LayoutCalculator.swift
│   └── DisplayToggleApp/       # Application target (AppKit status bar UI)
│       ├── AppDelegate.swift
│       ├── MenuBuilder.swift
│       ├── StatusBarController.swift
│       └── main.swift
└── Tests/
    └── DisplayToggleCoreTests/ # Unit tests (Swift Testing)
        ├── LayoutCalculatorTests.swift
        └── MockDisplayManagerTests.swift
```

### Targets

1. **`DisplayToggleCore` (Library)**:
   - Core library managing display discovery, geometry translation, and reconfiguration.
   - Interfaces directly with macOS `CoreGraphics` APIs (`CGGetActiveDisplayList`, `CGMainDisplayID`, `CGBeginDisplayConfiguration`, `CGConfigureDisplayOrigin`, `CGCompleteDisplayConfiguration`) and AppKit `NSScreen` (for localized display names).
   - Supports dependency injection (`displayProvider`, `displayReconfigurer`) for deterministic, headless-safe unit testing without requiring physical displays.
   - Implements `LayoutCalculator` for computing translation vectors $(\Delta x, \Delta y)$ and next toggle targets.
   - Manages display notifications via `CGDisplayRegisterReconfigurationCallback`.

2. **`DisplayToggleApp` (Executable)**:
   - Standalone menu bar application running as an accessory agent (`NSApp.setActivationPolicy(.accessory)`).
   - Manages the `NSStatusItem` in the system menu bar.
   - Routes mouse clicks (`.leftMouseUp`, `.rightMouseUp`, Option-clicks).
   - Generates menus dynamically via `MenuBuilder` and presents dropdowns via native AppKit menu presentation.

3. **`DisplayToggleCoreTests` (Test Suite)**:
   - Automated unit tests built with Apple's `Testing` framework (`import Testing`).
   - Covers horizontal swaps, vertical stacked arrangements, 3-display matrices, error conditions, and `DisplayManaging` protocol behaviors.

---

## Prerequisites

- **macOS**: macOS 15.0 (Sequoia) or later
- **Swift**: Swift 6.0+ (Xcode 16+ or Apple Command Line Tools)

---

## Building & Running

### Build (Debug)
```bash
swift build
```

### Run Application
```bash
swift run DisplayToggleApp
```
The application will launch and appear in the macOS menu bar.

### Build (Release)
```bash
swift build -c release
```
The optimized release binary is located at `.build/release/DisplayToggleApp`.

You can run it directly:
```bash
.build/release/DisplayToggleApp
```

---

## Testing

Run the full automated test suite:

```bash
swift test
```

### Parallel Execution
```bash
swift test --parallel
```

### Run Specific Test Suite
```bash
swift test --filter LayoutCalculatorTests
```

---

## VS Code Setup

The repository is configured for a first-class developer experience in VS Code.

### Recommended Extensions
When opening the workspace in VS Code, install the recommended extensions prompted via `.vscode/extensions.json`:
- **Swift (`swiftlang.swift-vscode`)**: Provides language server protocol (SourceKit-LSP) integration, autocompletion, diagnostics, and jump-to-definition.
- **CodeLLDB (`vadimcn.vscode-lldb`)**: Provides native LLDB debugging for Swift executables.
- **GitHub Pull Requests and Issues (`github.vscode-pull-request-github`)**: In-editor code review and PR workflows.

### Tasks (`.vscode/tasks.json`)
- **`swift: Build Debug`** (`Cmd+Shift+B`): Runs `swift build` and maps diagnostics via `$swift-compile`.
- **`swift: Run Tests`**: Runs `swift test` to execute the test suite.

### Debugging (`.vscode/launch.json`)
Press **F5** (or navigate to Run & Debug) and select **Debug DisplayToggleApp**:
- Builds the debug executable automatically via the `swift: Build Debug` pre-launch task.
- Launches `.build/debug/DisplayToggleApp` attached to the LLDB debugger.
- Set breakpoints in `Sources/` and inspect state interactively.

### Code Formatting
- Code formatting settings are pre-configured in `.vscode/settings.json` (`"editor.formatOnSave": true`).
- Apple's official `.swift-format` configuration is checked into the repository (4-space indentation, 120-character line length).

---

## Team Collaboration Guidelines

### Pure SPM (Zero Merge Conflicts)
- The project intentionally avoids `.xcodeproj` / `.pbxproj` project bundles.
- All targets, dependencies, compiler flags, and build configurations are strictly versioned in `Package.swift`.
- Developers preferring Xcode can simply open the package at any time:
  ```bash
  open Package.swift
  ```
  No project files or scheme metadata will pollute Git history.

### Git Worktree Workflow
- **Do not ever push directly to `main` (or `master`).**
- Always develop feature branches using Git worktrees rooted under `.worktrees/`:
  ```bash
  git worktree add .worktrees/<feature-branch> -b <feature-branch>
  ```
- Make commits following Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`).
- Always submit pull requests for code review.

---

## Coordinate Translation Math Reference

In macOS CoreGraphics, the "main display" is defined as the display positioned at origin `(0, 0)`.

Given $N$ displays $D_1, D_2, \dots, D_N$ where display $D_i$ has origin $(x_i, y_i)$:
To make display $D_T$ (currently at $(x_T, y_T)$) the main display:

$$\Delta x = -x_T, \quad \Delta y = -y_T$$

$$\forall i \in \{1, \dots, N\}: \quad (x_i', y_i') = (x_i + \Delta x, y_i + \Delta y)$$

- By definition:
  $$(x_T', y_T') = (x_T - x_T, y_T - y_T) = (0, 0)$$
  which designates $D_T$ as the main display.
- Pairwise relative offsets are strictly invariant:
  $$(x_j' - x_i', y_j' - y_i') = (x_j - x_i, y_j - y_i)$$
  ensuring no monitors overlap or change their relative spatial orientation.
