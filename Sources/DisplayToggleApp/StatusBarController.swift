import AppKit
import DisplayToggleCore

@MainActor
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
            Task { @MainActor [weak self] in
                self?.updateUI()
            }
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
