import CoreGraphics
import Foundation
import IOKit

/// Puts all connected displays to sleep.
///
/// Primary path — `/usr/bin/pmset displaysleepnow`: real hardware sleep of
/// the panels (not a black overlay). The Mac keeps running — background
/// processes, Docker and servers are not affected. Wake is standard: any
/// key press or mouse movement. No admin rights or extra permissions
/// are required.
///
/// macOS 26 note: the IOKit `IODisplayWrangler` service with the
/// `IORequestIdle` property returns KERN_SUCCESS but does not physically
/// sleep the displays, so IOKit is kept only as a fallback.
///
/// Phantom-wake guard: some input devices (e.g. gaming keyboards with
/// backlighting) may emit a single HID event a fraction of a second after
/// the displays fall asleep, instantly turning the screen back on. So after
/// `verifyDelay` seconds the app checks the display state via
/// `CGDisplayIsAsleep` and retries if needed (at most `maxAttempts` times).
enum DisplaySleep {

    private static let maxAttempts = 3
    private static let verifyDelay: TimeInterval = 4.0

    /// Guards against re-entry while a "sleep → verify" cycle is running.
    private static var sequenceInProgress = false

    /// Entry point: called on left click of the menu bar icon.
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
                // Displays are asleep — cycle complete.
                sequenceInProgress = false
            } else {
                // Something (an input device) already woke the display — retry.
                performSleep(attempt: attempt + 1)
            }
        }
    }

    /// Primary path: the system command, executed as the current user —
    /// no sudo needed.
    @discardableResult
    private static func sleepViaPmset() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        do {
            try process.run()
            return true
        } catch {
            NSLog("DisplaySleep: failed to launch pmset: \(error.localizedDescription)")
            return false
        }
    }

    /// Fallback path via IOKit (in case pmset is unavailable).
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
