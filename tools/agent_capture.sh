#!/usr/bin/env bash
# Render layout screenshots from a Linux agent sandbox (needs Xvfb + Mesa, which the Cowork
# VM has). Uses the project copy prepared by tools/agent_test.sh (run that first).
#
#   tools/agent_capture.sh <out_dir> <scenario> <locale> <WxH> [<WxH> ...]
#
# Example: tools/agent_capture.sh build/review starter_egg de 750x1334 1536x2048 2560x1440
set -uo pipefail
OUT="$1"; SCENARIO="$2"; LOCALE="$3"; shift 3
ARCH="$(uname -m)"; [[ "$ARCH" == "aarch64" ]] && ARCH="arm64"
GODOT="$HOME/godot/Godot_v4.6.1-stable_linux.${ARCH}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$HOME/work/proj"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
rsync -a --exclude .git --exclude .godot --exclude build "$SRC/" "$WORK/"
for size in "$@"; do
  w="${size%x*}"; h="${size#*x}"
  file="$OUT/${SCENARIO}_${LOCALE}_${w}x${h}.png"
  timeout 90 xvfb-run -a -s "-screen 0 $((w + 64))x$((h + 64))x24" "$GODOT" --rendering-driver opengl3 \
    --path "$WORK" --log-file /tmp/dragos-capture.log --script tools/capture_layout.gd -- \
    "$SCENARIO" "$w" "$h" "$LOCALE" "$file" 2>&1 | grep -E 'Saved|SCRIPT ERROR|^ERROR' | head -3
done
