import CoreGraphics
import Foundation
import IOKit

/// Перевод всех подключённых дисплеев в сон.
///
/// Основной путь — `/usr/bin/pmset displaysleepnow`: настоящий аппаратный
/// сон панелей (не «чёрный экран»). Mac при этом продолжает работать —
/// все фоновые процессы, Docker и серверы не затрагиваются. Пробуждение
/// стандартное: любая клавиша или движение мыши. Прав администратора
/// и дополнительных разрешений не требуется.
///
/// Нюанс macOS 26: сервис IOKit `IODisplayWrangler` со свойством
/// `IORequestIdle` возвращает KERN_SUCCESS, но физически не усыпляет
/// дисплеи, поэтому IOKit оставлен только как фолбэк.
///
/// Защита от «фантомных» пробуждений: некоторые устройства ввода
/// (например, игровые клавиатуры с подсветкой) способны отправить
/// единичное HID-событие через долю секунды после засыпания дисплея,
/// из-за чего экран мгновенно включается обратно. Поэтому через
/// `verifyDelay` секунд приложение проверяет состояние дисплея через
/// `CGDisplayIsAsleep` и при необходимости повторяет усыпление
/// (не более `maxAttempts` раз).
enum DisplaySleep {

    private static let maxAttempts = 3
    private static let verifyDelay: TimeInterval = 4.0

    /// Защита от повторного входа, пока идёт цикл «сон → проверка».
    private static var sequenceInProgress = false

    /// Точка входа: вызывается по левому клику на иконке.
    static func sleepDisplays() {
        guard !sequenceInProgress else { return }
        sequenceInProgress = true
        performSleep(attempt: 1)
    }

    private static func performSleep(attempt: Int) {
        if !sleepViaPmset() {
            sleepViaIOKit()
        }

        guard attempt < maxAttempts else {
            sequenceInProgress = false
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + verifyDelay) {
            if CGDisplayIsAsleep(CGMainDisplayID()) != 0 {
                // Дисплеи спят — цикл завершён.
                sequenceInProgress = false
            } else {
                // Кто-то (устройство ввода) уже разбудил дисплей — повторяем.
                performSleep(attempt: attempt + 1)
            }
        }
    }

    /// Основной путь: системная команда, выполняется от имени текущего
    /// пользователя, sudo не нужен.
    @discardableResult
    private static func sleepViaPmset() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        do {
            try process.run()
            return true
        } catch {
            NSLog("DisplaySleep: не удалось запустить pmset: \(error.localizedDescription)")
            return false
        }
    }

    /// Запасной путь через IOKit (на случай, если pmset недоступен).
    private static func sleepViaIOKit() {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IODisplayWrangler")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS,
              iterator != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(iterator) }

        while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
            IORegistryEntrySetCFProperty(service, "IORequestIdle" as CFString, kCFBooleanTrue)
            IOObjectRelease(service)
        }
    }
}
