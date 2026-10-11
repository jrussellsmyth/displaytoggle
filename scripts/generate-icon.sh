#!/bin/bash
set -euo pipefail

# Generates Resources/AppIcon.icns from a square PNG source image (e.g. 1024x1024)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_IMAGE="${1:-$ROOT_DIR/Resources/DisplayToggle.png}"

if [ ! -f "$SRC_IMAGE" ]; then
    echo "Error: Source image not found at '$SRC_IMAGE'" >&2
    echo "Usage: ./scripts/generate-icon.sh [path/to/icon.png]" >&2
    exit 1
fi

TMP_DIR="$(mktemp -d -t displaytoggle_iconset_XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
ICONSET_DIR="$TMP_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

echo "==> Generating iconset sizes from $SRC_IMAGE..."
sips -z 16 16     "$SRC_IMAGE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32     "$SRC_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$SRC_IMAGE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64     "$SRC_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$SRC_IMAGE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256   "$SRC_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$SRC_IMAGE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512   "$SRC_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$SRC_IMAGE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$SRC_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

echo "==> Converting iconset into Resources/AppIcon.icns..."
iconutil -c icns "$ICONSET_DIR" -o "$ROOT_DIR/Resources/AppIcon.icns"

echo "==> Successfully created $ROOT_DIR/Resources/AppIcon.icns!"
