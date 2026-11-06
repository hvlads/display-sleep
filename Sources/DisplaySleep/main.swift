import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// .accessory: приложение живёт только в строке меню, без иконки в Dock
app.setActivationPolicy(.accessory)
app.run()
