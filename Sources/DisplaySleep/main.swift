import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// .accessory: the app lives only in the menu bar, with no Dock icon
app.setActivationPolicy(.accessory)
app.run()
