import Cocoa

/// Делегат приложения: создаёт NSStatusItem и обрабатывает клики.
///
/// Поведение:
///  - Левый клик  → немедленно усыпить все дисплеи (без меню и подтверждений).
///  - Правый клик → маленькое служебное меню: автозапуск при входе, выход.
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
        button.toolTip = "Display Sleep — клик: выключить экраны"

        button.target = self
        button.action = #selector(handleClick(_:))
        // Реагируем и на левый, и на правый клик
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        switch NSApp.currentEvent?.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            // Левый клик: один клик — экраны спят. Никаких меню.
            DisplaySleep.sleepDisplays()
        }
    }

    // MARK: - Служебное меню (правый клик)

    private func showContextMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let loginItem = NSMenuItem(
            title: "Запускать при входе",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = launchAtLogin.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Выход",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Временно назначаем меню, показываем его и сразу снимаем,
        // чтобы левый клик оставался «мгновенным действием».
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    /// После закрытия меню убираем его из statusItem,
    /// иначе следующий левый клик откроет меню вместо сна дисплеев.
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
