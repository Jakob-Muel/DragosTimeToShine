#!/usr/bin/env bash
# Install Godot (Linux x86_64) and the web export templates into the CI cache paths.
set -euo pipefail
: "${GODOT_VERSION:?GODOT_VERSION must be set}"
mkdir -p "$HOME/.cache/dragos-godot"
curl --fail --location --retry 3 \
  "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
  --output /tmp/godot.zip
unzip -q /tmp/godot.zip -d "$HOME/.cache/dragos-godot"
mv "$HOME/.cache/dragos-godot/Godot_v${GODOT_VERSION}_linux.x86_64" "$HOME/.cache/dragos-godot/godot"
chmod +x "$HOME/.cache/dragos-godot/godot"

templates_dir="$HOME/.local/share/godot/export_templates/${GODOT_VERSION/-/.}"
curl --fail --location --retry 3 \
  "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz" \
  --output /tmp/export_templates.tpz
mkdir -p "$templates_dir"
unzip -jq /tmp/export_templates.tpz \
  templates/version.txt \
  templates/web_nothreads_debug.zip \
  templates/web_nothreads_release.zip \
  -d "$templates_dir"
