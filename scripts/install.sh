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

install_from_archive() {
  local archive_path="$1"
  local workdir="$2"

  echo "Extracting app bundle..."
  tar -xzf "$archive_path" -C "$workdir"

  if [[ ! -d "$workdir/$APP_NAME.app" ]]; then
    echo "Archive does not contain $APP_NAME.app" >&2
    exit 1
  fi

  if [[ -d "$INSTALL_DIR/$APP_NAME.app" ]]; then
    echo "Replacing existing app in $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
  fi

  cp -R "$workdir/$APP_NAME.app" "$INSTALL_DIR/"
  xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

  echo "Installed: $INSTALL_DIR/$APP_NAME.app"
  open "$INSTALL_DIR/$APP_NAME.app" || true
}

build_from_source() {
  local tmpdir="$1"
  local src_tgz="$tmpdir/source.tar.gz"

  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "No GitHub release asset is available, and xcodebuild is not installed for source build fallback." >&2
    exit 1
  fi

  echo "No release asset found. Falling back to source build from $REPO..."
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" -o "$src_tgz"
  tar -xzf "$src_tgz" -C "$tmpdir"

  local src_dir
  src_dir="$(find "$tmpdir" -maxdepth 1 -type d -name "*-*" | head -n 1)"

  if [[ -z "$src_dir" || ! -d "$src_dir" ]]; then
    echo "Could not locate extracted source directory." >&2
    exit 1
  fi

  if [[ -x "$src_dir/scripts/bootstrap-xcodeproj.sh" ]]; then
    (cd "$src_dir" && scripts/bootstrap-xcodeproj.sh)
  fi

  echo "Building app..."
  xcodebuild \
    -project "$src_dir/LiquidSpeedBar.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$tmpdir/DerivedData" \
    clean build >/dev/null

  local built_app="$tmpdir/DerivedData/Build/Products/Release/$APP_NAME.app"
  if [[ ! -d "$built_app" ]]; then
    echo "Build completed but app bundle was not found at expected path: $built_app" >&2
    exit 1
  fi

  if [[ -d "$INSTALL_DIR/$APP_NAME.app" ]]; then
    echo "Replacing existing app in $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
  fi

  cp -R "$built_app" "$INSTALL_DIR/"
  xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

  echo "Installed from source build: $INSTALL_DIR/$APP_NAME.app"
  open "$INSTALL_DIR/$APP_NAME.app" || true
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Fetching latest release from $REPO..."
asset_url=""
if release_json="$(curl -fsSL "$API_URL" 2>/dev/null)"; then
  asset_url="$(echo "$release_json" | jq -r '.assets[]? | select(.name | test("\\.app\\.tar\\.gz$")) | .browser_download_url' | head -n 1)"
fi

if [[ -n "$asset_url" && "$asset_url" != "null" ]]; then
  echo "Downloading: $asset_url"
  archive_path="$tmpdir/$APP_NAME.app.tar.gz"
  curl -fL "$asset_url" -o "$archive_path"
  install_from_archive "$archive_path" "$tmpdir"
else
  build_from_source "$tmpdir"
fi
