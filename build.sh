#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "Building Snappy…"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/Snappy"
STAGE="$ROOT/Snappy.app"
INSTALL_APP="/Applications/Snappy.app"

rm -rf "$STAGE"
mkdir -p "$STAGE/Contents/MacOS"
mkdir -p "$STAGE/Contents/Resources"

cp "$BIN" "$STAGE/Contents/MacOS/Snappy"
cp "$ROOT/Info.plist" "$STAGE/Contents/Info.plist"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Resources/AppIcon.icns" "$STAGE/Contents/Resources/AppIcon.icns"
fi

IDENTITY="$("$ROOT/ensure-signing-identity.sh" | tail -n 1)"
echo "Signing with: $IDENTITY"
codesign --force --deep --options runtime --sign "$IDENTITY" --timestamp=none "$STAGE"

echo "Installing to $INSTALL_APP"
rm -rf "$INSTALL_APP"
cp -R "$STAGE" "$INSTALL_APP"
codesign --force --deep --options runtime --sign "$IDENTITY" --timestamp=none "$INSTALL_APP"

echo ""
echo "Installed: $INSTALL_APP"
echo "Open with: open \"$INSTALL_APP\""
echo ""
echo "First run: enable Snappy in System Settings → Privacy & Security → Accessibility."
