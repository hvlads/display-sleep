# Display Sleep

[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A tiny macOS menu bar utility: **one click on the icon puts every connected display to sleep**. No menus, no confirmations, no Dock icon — the Mac itself keeps running, so your servers, Docker containers and bots are never interrupted.

[Русская версия README](README.ru.md)

## Why

Existing "sleep display" shortcuts either lock the session, show a fake black overlay, or require scripting. Display Sleep uses the real hardware display-sleep mechanism — the same one triggered by `pmset displaysleepnow`:

- Displays power off physically (not a black window).
- The system does **not** sleep — CPU, network and all processes keep working.
- Wake is standard: press any key or move the mouse.
- Zero permissions, zero admin rights, zero dependencies.

## Features

- **Left click** — all displays sleep instantly.
- **Right click** — small service menu: *Launch at Login* toggle and *Quit*.
- **Phantom-wake guard** — some input devices (e.g. gaming keyboards) emit a stray HID event a moment after the displays sleep, instantly waking them. The app verifies the display state after 4 seconds (`CGDisplayIsAsleep`) and retries, up to 3 attempts.
- **Lightweight** — pure AppKit `NSStatusItem`, ~10 MB RAM, ~0% CPU, sandbox-free, no entitlements.
- **Launch at login** via `SMAppService` (macOS 13+).

## Requirements

- macOS 13 Ventura or later (developed and tested on macOS 26, Apple Silicon)
- Swift toolchain (Xcode or Command Line Tools) — only for building

## Build & Install

```bash
git clone https://github.com/<your-username>/display-sleep.git
cd display-sleep

# Build the .app bundle
./build_app.sh

# Or build and install to /Applications in one step
./build_app.sh install
open "/Applications/Display Sleep.app"
```

On first launch macOS may warn about an unsigned app (the build uses ad-hoc signing): right-click the app → **Open**, or allow it in **System Settings → Privacy & Security**.

> The project is a plain SwiftPM package — if you have Xcode installed, just open the folder and press **⌘R**.

## Usage

| Action | Result |
|---|---|
| Left click on the menu bar icon | All displays sleep immediately |
| Any key / mouse movement | Displays wake (standard macOS behavior, session is not locked) |
| Right click | Menu: toggle *Launch at Login*, *Quit* |

**Launch at login** works when the app is installed as a bundle in `/Applications` (toggle it via right-click), or add it manually in **System Settings → General → Login Items**.

## How it works

```
NSStatusItem (left click)
        │
        ▼
/usr/bin/pmset displaysleepnow      ← real hardware display sleep
        │
        ├─ spawn failed → IOKit IODisplayWrangler / IORequestIdle (fallback)
        │
        ▼
verify after 4 s: CGDisplayIsAsleep?
        └─ awake → retry (up to 3 attempts total)
```

> Note: on recent macOS versions the IOKit `IODisplayWrangler` / `IORequestIdle` path reports success but does not actually sleep the displays, which is why `pmset` is the primary mechanism here.

**Permissions:** none. Neither `pmset displaysleepnow` nor the IOKit fallback requires sudo, Accessibility, Automation or any other grant — every click executes instantly as the current user.

## Uninstall

```bash
# Quit via right-click → Quit, then:
rm -rf "/Applications/Display Sleep.app"
# Remove the login item in System Settings → General → Login Items if enabled
```

## Project structure

```
├── Package.swift                  # SwiftPM manifest (macOS 13+)
├── Sources/DisplaySleep/
│   ├── main.swift                 # Entry point, .accessory activation policy
│   ├── AppDelegate.swift          # NSStatusItem, click handling, service menu
│   ├── DisplaySleep.swift         # pmset + IOKit fallback + phantom-wake retry
│   └── LaunchAtLogin.swift        # SMAppService wrapper
├── Resources/Info.plist           # LSUIElement, bundle metadata
└── build_app.sh                   # Builds the .app bundle (+ optional install)
```

## License

[MIT](LICENSE) © 2026 Vladislav
