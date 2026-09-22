#!/usr/bin/env bash
# Run the headless test suites from a Linux agent sandbox (Cowork VM, Codex cloud, CI-like).
# Downloads Godot 4.6.1 for the current Linux architecture into ~/godot, copies the project
# to ~/work/proj (so the user's .godot cache and saves are never touched), imports assets
# once, then runs each suite with a timeout. A failed assert makes Godot hang instead of
# exiting, so the timeout is what turns it into a failure.
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
SUITES=("$@")
[[ ${#SUITES[@]} -eq 0 ]] && SUITES=(smoke domain starter_progression random_eggs attribute_genetics \
  training_contract training_session flame_shooter screen_routing ui_safe_area font_coverage seeded_dragon)

if [[ ! -x "$GODOT" ]]; then
  mkdir -p "$GODOT_DIR"
  curl -sSL --retry 3 -o "$GODOT_DIR/godot.zip" \
    "https://github.com/godotengine/godot-builds/releases/download/${VERSION}/Godot_v${VERSION}_linux.${ARCH}.zip"
  unzip -oq "$GODOT_DIR/godot.zip" -d "$GODOT_DIR" && chmod +x "$GODOT"
fi

mkdir -p "$WORK"
rsync -a --delete --exclude .git --exclude .godot --exclude build "$SRC/" "$WORK/"

if [[ ! -d "$WORK/.godot/imported" || "${FULL_IMPORT:-0}" == "1" ]]; then
  echo "Importing assets (first run takes a few minutes)..."
  timeout 900 "$GODOT" --headless --editor --import --path "$WORK" --log-file /tmp/dragos-import.log >/dev/null 2>&1
fi

failed=0
for suite in "${SUITES[@]}"; do
  out="$(timeout 60 "$GODOT" --headless --path "$WORK" --log-file "/tmp/dragos-${suite}.log" \
    --script "tests/${suite}_test.gd" 2>&1)"
  rc=$?
  if [[ $rc -eq 0 ]] && grep -q "valid" <<<"$out"; then
    echo "PASS $suite"
  else
    failed=1
    echo "FAIL $suite (exit $rc)"
    grep -E "SCRIPT ERROR|Assertion|ERROR" <<<"$out" | head -5 | sed 's/^/    /'
  fi
done
exit $failed
