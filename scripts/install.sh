#!/bin/bash
# One-line install: curl -fsSL https://raw.githubusercontent.com/Arjun-Bhandari/Island/main/scripts/install.sh | bash
# Downloads the latest release into /Applications and opens it. Island is
# unsigned, so this also clears the quarantine flag that makes Gatekeeper
# block it ("Island can't be opened") on first launch.
set -euo pipefail

URL="https://github.com/Arjun-Bhandari/Island/releases/latest/download/Island.zip"
DEST="/Applications/Island.app"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ "$(uname)" != "Darwin" ]; then
    echo "Island only runs on macOS." >&2
    exit 1
fi

echo "==> Downloading the latest Island..."
curl -fL --progress-bar "$URL" -o "$TMP/Island.zip"
ditto -x -k "$TMP/Island.zip" "$TMP"

if pgrep -xq Island; then
    echo "==> Quitting the running copy..."
    osascript -e 'quit app "Island"' 2>/dev/null || pkill -x Island || true
    sleep 1
fi

echo "==> Installing to $DEST..."
SUDO=""
[ -w /Applications ] || SUDO="sudo"
$SUDO rm -rf "$DEST"
$SUDO ditto "$TMP/Island.app" "$DEST"
$SUDO xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo "==> Opening Island..."
open "$DEST"
echo "Done. Look at your notch — a welcome tour will walk you through the rest."
