import Cocoa

/// Application delegate: creates the NSStatusItem and handles clicks.
///
/// Behavior:
///  - Left click  → immediately sleep all displays (no menus, no confirmations).
///  - Right click → small service menu: launch at login toggle, quit.
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private let launchAtLogin = LaunchAtLogin()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }
        button.image = NSImage(
            systemSymbolName: "display",
            accessibilityDescription: "Display Sleep"
        )
        button.image?.isTemplate = true
        button.toolTip = "Display Sleep — click to sleep displays"

        button.target = self
        button.action = #selector(handleClick(_:))
        // React to both left and right clicks
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        switch NSApp.currentEvent?.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            // Left click: one click — displays sleep. No menus.
            DisplaySleep.sleepDisplays()
        }
    }

    // MARK: - Service menu (right click)

    private func showContextMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = launchAtLogin.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Temporarily attach the menu, show it, then detach it right away
        // so the left click stays an instant action.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    /// After the menu closes, remove it from the status item —
    /// otherwise the next left click would open the menu instead of
    /// sleeping the displays.
    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    @objc private func toggleLaunchAtLogin() {
        launchAtLogin.set(!launchAtLogin.isEnabled)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
