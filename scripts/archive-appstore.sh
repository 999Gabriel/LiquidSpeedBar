#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="LiquidSpeedBar"
TEAM_ID="${DEVELOPER_TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.the999gabriel.liquidspeedbar}"
DIST_DIR="$ROOT_DIR/dist/appstore"
ARCHIVE_PATH="$DIST_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$DIST_DIR/export"
EXPORT_OPTIONS_PLIST="$DIST_DIR/ExportOptions.plist"

if [[ -z "$TEAM_ID" ]]; then
  echo "Set DEVELOPER_TEAM_ID before running this script." >&2
  echo "Example: DEVELOPER_TEAM_ID=ABCDE12345 scripts/archive-appstore.sh" >&2
  exit 1
fi

"$ROOT_DIR/scripts/generate-icon-assets.sh"
"$ROOT_DIR/scripts/bootstrap-xcodeproj.sh"

mkdir -p "$DIST_DIR"

echo "Archiving for App Store..."
xcodebuild \
  -project "$ROOT_DIR/LiquidSpeedBar.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGN_ENTITLEMENTS="$ROOT_DIR/Config/AppStore.entitlements" \
  clean archive

cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
  <key>stripSwiftSymbols</key>
  <true/>
</dict>
</plist>
PLIST

echo "Exporting signed package for App Store Connect..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "Done. Exported package should be in: $EXPORT_PATH"
