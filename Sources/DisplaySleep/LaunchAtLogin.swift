import Foundation
import ServiceManagement

/// Автозапуск при входе через SMAppService (macOS 13+).
///
/// Важно: регистрация работает только когда приложение собрано как
/// настоящий .app-бандл и лежит в /Applications (или другой постоянной
/// папке). При запуске бинарника напрямую из .build регистрация не сработает.
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
            // Не падаем: просто сообщаем в лог. Пользователь может включить
            // автозапуск вручную: Системные настройки → Основные → Объекты входа.
            NSLog("DisplaySleep: не удалось изменить автозапуск: \(error.localizedDescription)")
        }
    }
}
