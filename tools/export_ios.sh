#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
GODOT_BIN_PATH=${GODOT_BIN_PATH:-/Applications/Godot.app/Contents/MacOS/Godot}
EXPORT_MODE=${1:-debug}
EXPORT_DIR="$PROJECT_ROOT/build/ios"
IPA_PATH="$EXPORT_DIR/DragosTimeToShine.ipa"
APP_PATH="$EXPORT_DIR/DragosTimeToShine.xcarchive/Products/Applications/DragosTimeToShine.app"
PRESET_PATH="$PROJECT_ROOT/export_presets.cfg"

if ! grep -Fq 'entitlements/additional="<key>com.apple.developer.healthkit</key>\n<true/>"' "$PRESET_PATH"; then
	echo "ERROR: The iOS export preset is missing the HealthKit entitlement." >&2
	exit 1
fi

if ! grep -Fq 'plugins/StepCounterPlugin=true' "$PRESET_PATH"; then
	echo "ERROR: The iOS export preset does not enable StepCounterPlugin." >&2
	exit 1
fi

if [ ! -x "$GODOT_BIN_PATH" ]; then
	echo "ERROR: Godot was not found at $GODOT_BIN_PATH" >&2
	exit 1
fi

mkdir -p "$EXPORT_DIR"

case "$EXPORT_MODE" in
	debug)
		"$GODOT_BIN_PATH" --headless --log-file "$EXPORT_DIR/godot-export.log" --path "$PROJECT_ROOT" --export-debug "iOS" "$IPA_PATH"
		;;
	release)
		"$GODOT_BIN_PATH" --headless --log-file "$EXPORT_DIR/godot-export.log" --path "$PROJECT_ROOT" --export-release "iOS" "$IPA_PATH"
		;;
	*)
		echo "Usage: tools/export_ios.sh [debug|release]" >&2
		exit 1
		;;
esac

if [ ! -d "$APP_PATH" ]; then
	echo "ERROR: The signed app archive was not produced at $APP_PATH" >&2
	exit 1
fi

SIGNED_ENTITLEMENTS=$(/usr/bin/codesign -d --entitlements - "$APP_PATH" 2>&1)
if ! printf '%s\n' "$SIGNED_ENTITLEMENTS" | grep -Fq 'com.apple.developer.healthkit'; then
	echo "ERROR: Export succeeded, but the signed app has no HealthKit entitlement." >&2
	exit 1
fi

if ! /usr/libexec/PlistBuddy -c 'Print :NSHealthShareUsageDescription' "$APP_PATH/Info.plist" >/dev/null; then
	echo "ERROR: Export succeeded, but Info.plist has no HealthKit read explanation." >&2
	exit 1
fi

if ! grep -Fq 'StepCounterPlugin' "$EXPORT_DIR/DragosTimeToShine/dummy.cpp"; then
	echo "ERROR: Export succeeded, but StepCounterPlugin was not registered." >&2
	exit 1
fi

echo "Validated iOS export: $IPA_PATH"
echo "HealthKit entitlement, privacy text, and native plugin are present."
