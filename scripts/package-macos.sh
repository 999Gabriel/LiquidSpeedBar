#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LiquidSpeedBar"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
XCODE_DERIVED_DATA="$ROOT_DIR/.build/xcode-dist"
XCODE_APP_PATH="$XCODE_DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
VERSION="${VERSION:-$(git -C "$ROOT_DIR" describe --tags --always --dirty 2>/dev/null || date +%Y.%m.%d)}"
DMG_NAME="$APP_NAME-macOS-$VERSION.dmg"
TAR_NAME="$APP_NAME-macOS-$VERSION.app.tar.gz"
APP_DIR="$DIST_DIR/$APP_NAME.app"

echo "[1/6] Generating icon assets..."
"$ROOT_DIR/scripts/generate-icon-assets.sh"

echo "[2/6] Generating Xcode project..."
"$ROOT_DIR/scripts/bootstrap-xcodeproj.sh"

echo "[3/6] Building release app bundle..."
rm -rf "$XCODE_DERIVED_DATA"
xcodebuild \
  -project "$ROOT_DIR/LiquidSpeedBar.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$XCODE_DERIVED_DATA" \
  build >/dev/null

if [[ ! -d "$XCODE_APP_PATH" ]]; then
  echo "Build failed: app bundle not found at $XCODE_APP_PATH" >&2
  exit 1
fi

echo "[4/6] Preparing distributable app..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
cp -R "$XCODE_APP_PATH" "$APP_DIR"

echo "[5/6] Creating release archives..."
tar -czf "$DIST_DIR/$TAR_NAME" -C "$DIST_DIR" "$APP_NAME.app"

DMG_STAGING="$DIST_DIR/dmg-root"
mkdir -p "$DMG_STAGING"
cp -R "$APP_DIR" "$DMG_STAGING/"
ln -sfn /Applications "$DMG_STAGING/Applications"
cat > "$DMG_STAGING/Drag ${APP_NAME} to Applications.txt" <<TXT
To install:
1. Drag ${APP_NAME}.app onto Applications.
2. Launch ${APP_NAME} from Applications.
TXT
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$DIST_DIR/$DMG_NAME" >/dev/null
rm -rf "$DMG_STAGING"

echo "[6/6] Done"
echo "Created:"
echo "- $APP_DIR"
echo "- $DIST_DIR/$DMG_NAME"
echo "- $DIST_DIR/$TAR_NAME"
