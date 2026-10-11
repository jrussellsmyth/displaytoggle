import AppKit
import DisplayToggleCore

@MainActor
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

@MainActor
final class MenuActionHandler: NSObject {
    static let shared = MenuActionHandler()

    var onSelectDisplay: ((CGDirectDisplayID) -> Void)?
    var onRefresh: (() -> Void)?
    var onQuit: (() -> Void)?

    @objc func displaySelected(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? CGDirectDisplayID {
            onSelectDisplay?(id)
        } else if let number = sender.representedObject as? NSNumber {
            onSelectDisplay?(number.uint32Value)
        }
    }

    @objc func refreshClicked() {
        onRefresh?()
    }

    @objc func quitClicked() {
        onQuit?()
    }
}
