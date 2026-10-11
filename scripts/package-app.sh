#!/bin/bash
set -euo pipefail

# Package DisplayToggle into a native macOS .app bundle and distributable archives (.zip, .dmg)
# Usage: ./scripts/package-app.sh [VERSION] [--all | --app-only | --archives-only]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="1.0.0"
MODE="--all"

for arg in "$@"; do
    case "$arg" in
        --app-only|--archives-only|--all)
            MODE="$arg"
            ;;
        *)
            VERSION="$arg"
            ;;
    esac
done

BUILD_DIR="$ROOT_DIR/.build/release"
OUTPUT_DIR="$ROOT_DIR/dist"
APP_NAME="DisplayToggle"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"

build_app() {
    echo "==> Building $APP_NAME in Release mode..."
    swift build -c release --package-path "$ROOT_DIR"

    echo "==> Preparing output directory..."
    mkdir -p "$OUTPUT_DIR"

    echo "==> Creating $APP_NAME.app bundle structure..."
    rm -rf "$APP_BUNDLE"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"

    # Copy binary
    cp "$BUILD_DIR/DisplayToggleApp" "$APP_BUNDLE/Contents/MacOS/DisplayToggleApp"
    chmod +x "$APP_BUNDLE/Contents/MacOS/DisplayToggleApp"

    # Copy and update Info.plist with version
    INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
    if [ -f "$INFO_PLIST" ]; then
        cp "$INFO_PLIST" "$APP_BUNDLE/Contents/Info.plist"
        plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    fi

    # Copy icon if present
    if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
        cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
    fi

    # Code signing (ad-hoc by default, or with Developer ID + hardened runtime if environment variable is set)
    SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"
    echo "==> Signing bundle with identity: '$SIGNING_IDENTITY'..."
    SIGN_OPTS=(--force --deep)
    if [ "$SIGNING_IDENTITY" != "-" ]; then
        SIGN_OPTS+=(--options runtime --timestamp)
    fi
    codesign "${SIGN_OPTS[@]}" --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"

    echo "==> Verifying signature..."
    codesign --verify --deep --strict "$APP_BUNDLE"
}

build_archives() {
    if [ ! -d "$APP_BUNDLE" ]; then
        echo "Error: $APP_BUNDLE does not exist. Build the app bundle first." >&2
        exit 1
    fi

    # Create ZIP archive
    echo "==> Creating ZIP archive..."
    rm -f "$OUTPUT_DIR/$APP_NAME.zip"
    (cd "$OUTPUT_DIR" && zip -r -q "$APP_NAME.zip" "$APP_NAME.app")

    # Create DMG using native hdiutil
    echo "==> Creating DMG archive..."
    rm -f "$OUTPUT_DIR/$APP_NAME.dmg"
    DMG_STAGING="$OUTPUT_DIR/dmg_staging"
    rm -rf "$DMG_STAGING"
    mkdir -p "$DMG_STAGING"
    cp -R "$APP_BUNDLE" "$DMG_STAGING/"
    ln -s /Applications "$DMG_STAGING/Applications"
    if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
        cp "$ROOT_DIR/Resources/AppIcon.icns" "$DMG_STAGING/.VolumeIcon.icns"
        if command -v SetFile >/dev/null 2>&1; then
            SetFile -a C "$DMG_STAGING"
        fi
    fi

    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$DMG_STAGING" \
        -ov -format UDZO \
        "$OUTPUT_DIR/$APP_NAME.dmg" >/dev/null

    rm -rf "$DMG_STAGING"
}

case "$MODE" in
    --app-only)
        build_app
        ;;
    --archives-only)
        build_archives
        ;;
    --all)
        build_app
        build_archives
        ;;
esac

echo "==> Packaging complete for mode '$MODE'! Distributable files in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR"
