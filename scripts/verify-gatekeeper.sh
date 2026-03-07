#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-/Applications/LiquidSpeedBar.app}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH" >&2
  echo "Usage: scripts/verify-gatekeeper.sh /path/to/LiquidSpeedBar.app" >&2
  exit 1
fi

echo "== Gatekeeper assessment =="
spctl -a -vvv --type exec "$APP_PATH" || true
echo

echo "== Code signature details =="
codesign -dv --verbose=4 "$APP_PATH" 2>&1 || true
echo

echo "== Extended attributes =="
xattr -l "$APP_PATH" || true
echo

echo "== Staple validation =="
xcrun stapler validate "$APP_PATH" || true
