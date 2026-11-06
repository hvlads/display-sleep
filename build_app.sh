#!/bin/bash
# Собирает Display Sleep в готовый .app-бандл.
# Использование:
#   ./build_app.sh           — собрать в ./build/Display Sleep.app
#   ./build_app.sh install   — собрать и скопировать в /Applications
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Display Sleep"
APP_DIR="build/${APP_NAME}.app"
BINARY=".build/release/DisplaySleep"

echo "→ Сборка (release)…"
swift build -c release

echo "→ Создание бандла ${APP_DIR}…"
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "$BINARY" "${APP_DIR}/Contents/MacOS/"
cp "Resources/Info.plist" "${APP_DIR}/Contents/"

echo "→ Подпись (ad-hoc, для личного использования)…"
codesign --force --sign - "$APP_DIR"

echo "✓ Готово: ${APP_DIR}"

if [[ "${1:-}" == "install" ]]; then
    echo "→ Установка в /Applications…"
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP_DIR" "/Applications/${APP_NAME}.app"
    echo "✓ Установлено: /Applications/${APP_NAME}.app"
    echo "  Запустите: open \"/Applications/${APP_NAME}.app\""
fi
