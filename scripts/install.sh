#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-999Gabriel/LiquidSpeedBar}"
APP_NAME="${APP_NAME:-LiquidSpeedBar}"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
API_URL="https://api.github.com/repos/$REPO/releases/latest"

for cmd in curl tar jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

echo "Fetching latest release from $REPO..."
release_json="$(curl -fsSL "$API_URL")"

asset_url="$(echo "$release_json" | jq -r '.assets[] | select(.name | test("\\.app\\.tar\\.gz$")) | .browser_download_url' | head -n 1)"
if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
  echo "No .app.tar.gz asset found in latest release." >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading: $asset_url"
curl -fL "$asset_url" -o "$tmpdir/$APP_NAME.app.tar.gz"

echo "Extracting app bundle..."
tar -xzf "$tmpdir/$APP_NAME.app.tar.gz" -C "$tmpdir"

if [[ ! -d "$tmpdir/$APP_NAME.app" ]]; then
  echo "Archive does not contain $APP_NAME.app" >&2
  exit 1
fi

if [[ -d "$INSTALL_DIR/$APP_NAME.app" ]]; then
  echo "Replacing existing app in $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

cp -R "$tmpdir/$APP_NAME.app" "$INSTALL_DIR/"
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo "Installed: $INSTALL_DIR/$APP_NAME.app"
open "$INSTALL_DIR/$APP_NAME.app" || true
