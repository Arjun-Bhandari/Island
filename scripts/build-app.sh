#!/bin/bash
# Builds Island.app in release mode and zips it for distribution.
# Unsigned (ad-hoc signed) — friends right-click > Open the first time.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Island"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "==> Building release binary..."
swift build -c release

echo "==> Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc signing (no Developer account needed)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Zipping for distribution..."
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo ""
echo "Done:"
echo "  App: $APP_BUNDLE"
echo "  Zip: $ZIP_PATH"
echo ""
echo "First launch on another Mac: right-click the app > Open (unsigned build)."
