import Foundation
import ServiceManagement

/// Launch at login via SMAppService (macOS 13+).
///
/// Note: registration only works when the app is built as a real .app
/// bundle and lives in /Applications (or another permanent folder).
/// Running the binary directly from .build will not register it.
final class LaunchAtLogin {

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func set(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status != .enabled { return }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Don't crash: just log. The user can enable launch at login
            // manually in System Settings → General → Login Items.
            NSLog("DisplaySleep: failed to change launch-at-login: \(error.localizedDescription)")
        }
    }
}
