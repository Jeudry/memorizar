#!/usr/bin/env bash
# Empaqueta el build de macOS release en un .dmg distribuible.
#
#   flutter build macos --release
#   ./scripts/package_macos_dmg.sh
#
# Produce build/Memorizar.dmg con un alias a /Applications para arrastrar.
# NO firma ni notariza — eso requiere credenciales de Apple Developer y se
# corre aparte (codesign + notarytool) sobre el .app antes de empaquetar.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="frontend"
DMG_NAME="Memorizar"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_PATH="build/${DMG_NAME}.dmg"
STAGING="$(mktemp -d)"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: no existe $APP_PATH — corre primero: flutter build macos --release" >&2
  exit 1
fi

echo "→ Preparando staging…"
cp -R "$APP_PATH" "$STAGING/${DMG_NAME}.app"
ln -s /Applications "$STAGING/Applications"

echo "→ Creando $DMG_PATH…"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$DMG_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING"
echo "✓ Listo: $DMG_PATH"
