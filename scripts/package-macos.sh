#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LiquidSpeedBar"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build"
DMG_ASSETS_DIR="$BUILD_DIR/dmg"
DMG_SOURCE_DIR="$DMG_ASSETS_DIR/source"
XCODE_DERIVED_DATA="$ROOT_DIR/.build/xcode-dist"
XCODE_APP_PATH="$XCODE_DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
VERSION="${VERSION:-$(git -C "$ROOT_DIR" describe --tags --always --dirty 2>/dev/null || date +%Y.%m.%d)}"
DMG_NAME="$APP_NAME-macOS-$VERSION.dmg"
TAR_NAME="$APP_NAME-macOS-$VERSION.app.tar.gz"
APP_DIR="$DIST_DIR/$APP_NAME.app"
APP_NOTARY_ZIP="$DIST_DIR/$APP_NAME-macOS-$VERSION-notary.zip"
VOLUME_NAME="$APP_NAME Installer"

DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-$DEVELOPER_ID_APPLICATION}"
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
NOTARY_APPLE_ID="${NOTARY_APPLE_ID:-}"
NOTARY_APP_PASSWORD="${NOTARY_APP_PASSWORD:-}"
NOTARY_TEAM_ID="${NOTARY_TEAM_ID:-}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"
ALLOW_UNSIGNED_RELEASE="${ALLOW_UNSIGNED_RELEASE:-0}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

notary_submit() {
  local artifact_path="$1"
  if [[ -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
    xcrun notarytool submit "$artifact_path" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
    return
  fi

  xcrun notarytool submit "$artifact_path" \
    --apple-id "$NOTARY_APPLE_ID" \
    --password "$NOTARY_APP_PASSWORD" \
    --team-id "$NOTARY_TEAM_ID" \
    --wait
}

require_cmd xcodebuild
require_cmd tar
require_cmd swift
require_cmd create-dmg

if [[ -z "$SIGNING_IDENTITY" ]]; then
  if [[ "$ALLOW_UNSIGNED_RELEASE" == "1" ]]; then
    echo "WARNING: Building unsigned distribution artifacts (ALLOW_UNSIGNED_RELEASE=1)."
  else
    echo "ERROR: Missing Developer ID identity." >&2
    echo "Set DEVELOPER_ID_APPLICATION or SIGNING_IDENTITY for signed releases." >&2
    echo "If this is a local-only test build, set ALLOW_UNSIGNED_RELEASE=1." >&2
    exit 1
  fi
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  require_cmd codesign
  require_cmd ditto
  require_cmd spctl
  require_cmd xcrun

  if [[ "$SKIP_NOTARIZATION" != "1" ]]; then
    if [[ -z "$NOTARY_KEYCHAIN_PROFILE" && ( -z "$NOTARY_APPLE_ID" || -z "$NOTARY_APP_PASSWORD" || -z "$NOTARY_TEAM_ID" ) ]]; then
      echo "ERROR: Missing notarization credentials." >&2
      echo "Set NOTARY_KEYCHAIN_PROFILE, or set NOTARY_APPLE_ID, NOTARY_APP_PASSWORD, and NOTARY_TEAM_ID." >&2
      echo "Set SKIP_NOTARIZATION=1 only for local/internal testing." >&2
      exit 1
    fi
  fi
fi

echo "[1/8] Generating icon assets..."
"$ROOT_DIR/scripts/generate-icon-assets.sh"

echo "[2/8] Generating DMG assets..."
swift "$ROOT_DIR/scripts/generate-dmg-assets.swift" "$DMG_ASSETS_DIR"

echo "[3/8] Generating Xcode project..."
"$ROOT_DIR/scripts/bootstrap-xcodeproj.sh"

echo "[4/8] Building release app bundle..."
rm -rf "$XCODE_DERIVED_DATA"
xcodebuild \
  -project "$ROOT_DIR/LiquidSpeedBar.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$XCODE_DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build >/dev/null

if [[ ! -d "$XCODE_APP_PATH" ]]; then
  echo "Build failed: app bundle not found at $XCODE_APP_PATH" >&2
  exit 1
fi

echo "[5/8] Preparing distributable app..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
cp -R "$XCODE_APP_PATH" "$APP_DIR"

if [[ -n "$SIGNING_IDENTITY" ]]; then
  echo "[6/8] Signing app bundle with Developer ID..."
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$APP_DIR"
  codesign --verify --strict --deep --verbose=2 "$APP_DIR"

  if [[ "$SKIP_NOTARIZATION" != "1" ]]; then
    echo "[7/8] Notarizing app bundle..."
    rm -f "$APP_NOTARY_ZIP"
    ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$APP_NOTARY_ZIP"
    notary_submit "$APP_NOTARY_ZIP" >/dev/null
    xcrun stapler staple "$APP_DIR" >/dev/null
    xcrun stapler validate "$APP_DIR" >/dev/null
    rm -f "$APP_NOTARY_ZIP"
  else
    echo "[7/8] Skipping notarization (SKIP_NOTARIZATION=1)."
  fi
fi

echo "[8/8] Creating release archives..."
tar -czf "$DIST_DIR/$TAR_NAME" -C "$DIST_DIR" "$APP_NAME.app"

rm -rf "$DMG_SOURCE_DIR"
mkdir -p "$DMG_SOURCE_DIR"
ditto "$APP_DIR" "$DMG_SOURCE_DIR/$APP_NAME.app"

rm -f "$DIST_DIR/$DMG_NAME"
create-dmg \
  --volname "$VOLUME_NAME" \
  --window-pos 200 120 \
  --window-size 640 420 \
  --icon-size 128 \
  --text-size 14 \
  --icon "$APP_NAME.app" 180 210 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 460 210 \
  --background "$DMG_ASSETS_DIR/background.png" \
  --no-internet-enable \
  --hdiutil-quiet \
  "$DIST_DIR/$DMG_NAME" \
  "$DMG_SOURCE_DIR"

if [[ -n "$SIGNING_IDENTITY" ]]; then
  echo "Signing DMG and validating Gatekeeper checks..."
  codesign \
    --force \
    --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$DIST_DIR/$DMG_NAME"
  codesign --verify --verbose=2 "$DIST_DIR/$DMG_NAME"

  if [[ "$SKIP_NOTARIZATION" != "1" ]]; then
    notary_submit "$DIST_DIR/$DMG_NAME" >/dev/null
    xcrun stapler staple "$DIST_DIR/$DMG_NAME" >/dev/null
    xcrun stapler validate "$DIST_DIR/$DMG_NAME" >/dev/null
  fi

  spctl -a -vvv --type exec "$APP_DIR" >/dev/null
fi

echo "Done"
echo "Created:"
echo "- $APP_DIR"
echo "- $DIST_DIR/$DMG_NAME"
echo "- $DIST_DIR/$TAR_NAME"
