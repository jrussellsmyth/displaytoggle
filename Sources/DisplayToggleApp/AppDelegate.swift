import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory agent (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()
    }
}
