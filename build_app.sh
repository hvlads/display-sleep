#!/bin/bash
# Builds Display Sleep into a ready .app bundle.
# Usage:
#   ./build_app.sh           — build into ./build/Display Sleep.app
#   ./build_app.sh install   — build and copy to /Applications
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Display Sleep"
APP_DIR="build/${APP_NAME}.app"
BINARY=".build/release/DisplaySleep"

echo "→ Building (release)…"
swift build -c release

echo "→ Creating bundle ${APP_DIR}…"
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "$BINARY" "${APP_DIR}/Contents/MacOS/"
cp "Resources/Info.plist" "${APP_DIR}/Contents/"

echo "→ Signing (ad-hoc, for personal use)…"
codesign --force --sign - "$APP_DIR"

echo "✓ Done: ${APP_DIR}"

if [[ "${1:-}" == "install" ]]; then
    echo "→ Installing to /Applications…"
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP_DIR" "/Applications/${APP_NAME}.app"
    echo "✓ Installed: /Applications/${APP_NAME}.app"
    echo "  Run it with: open \"/Applications/${APP_NAME}.app\""
fi
