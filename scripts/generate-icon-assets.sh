#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON_PRIMARY="$ROOT_DIR/source/liquidspeedbar.png"
SOURCE_ICON_FALLBACK="$ROOT_DIR/Sources/LiquidSpeedBar/liquidspeedbar.png"
APPICONSET_DIR="$ROOT_DIR/Assets.xcassets/AppIcon.appiconset"
ASSET_ROOT="$ROOT_DIR/Assets.xcassets"

if [[ -f "$SOURCE_ICON_PRIMARY" ]]; then
  SOURCE_ICON="$SOURCE_ICON_PRIMARY"
elif [[ -f "$SOURCE_ICON_FALLBACK" ]]; then
  SOURCE_ICON="$SOURCE_ICON_FALLBACK"
else
  echo "Missing source icon. Expected one of:" >&2
  echo "- $SOURCE_ICON_PRIMARY" >&2
  echo "- $SOURCE_ICON_FALLBACK" >&2
  exit 1
fi

mkdir -p "$APPICONSET_DIR"
rm -f "$APPICONSET_DIR"/*.png

build_icon() {
  local size="$1"
  local out="$2"
  sips -z "$size" "$size" "$SOURCE_ICON" --out "$out" >/dev/null
}

build_icon 16 "$APPICONSET_DIR/icon_16x16.png"
build_icon 32 "$APPICONSET_DIR/icon_16x16@2x.png"
build_icon 32 "$APPICONSET_DIR/icon_32x32.png"
build_icon 64 "$APPICONSET_DIR/icon_32x32@2x.png"
build_icon 128 "$APPICONSET_DIR/icon_128x128.png"
build_icon 256 "$APPICONSET_DIR/icon_128x128@2x.png"
build_icon 256 "$APPICONSET_DIR/icon_256x256.png"
build_icon 512 "$APPICONSET_DIR/icon_256x256@2x.png"
build_icon 512 "$APPICONSET_DIR/icon_512x512.png"
build_icon 1024 "$APPICONSET_DIR/icon_512x512@2x.png"

cat > "$ASSET_ROOT/Contents.json" <<'JSON'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

cat > "$APPICONSET_DIR/Contents.json" <<'JSON'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "Generated app icon assets from: $SOURCE_ICON"
echo "- $APPICONSET_DIR"
