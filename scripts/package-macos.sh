#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LiquidSpeedBar"
BUNDLE_ID="com.the999gabriel.liquidspeedbar"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_BINARY="$ROOT_DIR/.build/release/$APP_NAME"
VERSION="${VERSION:-$(git -C "$ROOT_DIR" describe --tags --always --dirty 2>/dev/null || date +%Y.%m.%d)}"
DMG_NAME="$APP_NAME-macOS-$VERSION.dmg"
TAR_NAME="$APP_NAME-macOS-$VERSION.app.tar.gz"
APP_DIR="$DIST_DIR/$APP_NAME.app"

echo "[1/5] Building release binary..."
swift build -c release --package-path "$ROOT_DIR"

if [[ ! -x "$BUILD_BINARY" ]]; then
  echo "Build failed: executable not found at $BUILD_BINARY" >&2
  exit 1
fi

echo "[2/5] Creating .app bundle..."
rm -rf "$DIST_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_BINARY" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "[3/5] Signing app bundle (ad-hoc)..."
if ! codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1; then
  echo "Warning: ad-hoc codesign failed. Continuing unsigned." >&2
fi

echo "[4/5] Creating release archives..."
tar -czf "$DIST_DIR/$TAR_NAME" -C "$DIST_DIR" "$APP_NAME.app"

DMG_STAGING="$DIST_DIR/dmg-root"
mkdir -p "$DMG_STAGING"
cp -R "$APP_DIR" "$DMG_STAGING/"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$DIST_DIR/$DMG_NAME" >/dev/null
rm -rf "$DMG_STAGING"

echo "[5/5] Done"
echo "Created:"
echo "- $APP_DIR"
echo "- $DIST_DIR/$DMG_NAME"
echo "- $DIST_DIR/$TAR_NAME"
