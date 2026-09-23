#!/usr/bin/env bash
# Run the headless test suites from a Linux agent sandbox (Cowork VM, Codex cloud, CI-like).
# Downloads Godot 4.6.1 for the current Linux architecture into ~/godot, copies the project
# to ~/work/proj (so the user's .godot cache and saves are never touched), imports assets
# once, then hands over to tests/run_tests.sh (fail-fast on errors, per-suite timeout).
#
# Usage: tools/agent_test.sh [suite ...]   (default: all headless suites)
#        FULL_IMPORT=1 tools/agent_test.sh  (force a fresh asset import)
set -uo pipefail

VERSION="4.6.1-stable"
ARCH="$(uname -m)"; [[ "$ARCH" == "aarch64" ]] && ARCH="arm64"
GODOT_DIR="$HOME/godot"
GODOT="$GODOT_DIR/Godot_v${VERSION}_linux.${ARCH}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$HOME/work/proj"

if [[ ! -x "$GODOT" ]]; then
  mkdir -p "$GODOT_DIR"
  curl -sSL --retry 3 -o "$GODOT_DIR/godot.zip" \
    "https://github.com/godotengine/godot-builds/releases/download/${VERSION}/Godot_v${VERSION}_linux.${ARCH}.zip"
  unzip -oq "$GODOT_DIR/godot.zip" -d "$GODOT_DIR" && chmod +x "$GODOT"
fi

mkdir -p "$WORK"
rsync -a --delete --exclude .git --exclude .godot --exclude build "$SRC/" "$WORK/"

# Always import: incremental runs take seconds and refresh the class_name cache, which new
# scripts need. The first run (or FULL_IMPORT=1) imports every asset and takes minutes.
[[ "${FULL_IMPORT:-0}" == "1" ]] && rm -rf "$WORK/.godot"
[[ -d "$WORK/.godot/imported" ]] || echo "Importing assets (first run takes a few minutes)..."
timeout 900 "$GODOT" --headless --editor --import --path "$WORK" --log-file /tmp/dragos-import.log >/dev/null 2>&1

GODOT="$GODOT" PROJECT="$WORK" exec "$SRC/tests/run_tests.sh" "$@"
