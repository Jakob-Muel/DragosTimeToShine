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
TEMPLATE_PATH=${GODOT_IOS_TEMPLATE_PATH:-"$HOME/Library/Application Support/Godot/export_templates/4.6.1.stable/ios.zip"}
TEMPLATE_CHECK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dragos-ios-export.XXXXXX")

cleanup() {
	rm -rf "$TEMPLATE_CHECK_DIR"
}
trap cleanup EXIT

if [ ! -f "$TEMPLATE_PATH" ]; then
	echo "ERROR: Godot 4.6.1 iOS export template not found at $TEMPLATE_PATH" >&2
	exit 1
fi

for configuration in debug release; do
	template_library="$TEMPLATE_CHECK_DIR/libgodot-$configuration-simulator.a"
	unzip -p "$TEMPLATE_PATH" \
		"libgodot.ios.$configuration.xcframework/ios-arm64_x86_64-simulator/libgodot.a" \
		> "$template_library"
	if ! lipo -archs "$template_library" | grep -qw arm64; then
		echo "ERROR: The Godot $configuration iOS Simulator template has no arm64 slice." >&2
		echo "Run tools/repair_godot_ios_template.sh once, then export again." >&2
		exit 1
	fi
done

if ! awk '
	index($0, "entitlements/additional=\"<key>com.apple.developer.healthkit</key>") {
		getline
		if ($0 == "<true/>\"") found = 1
	}
	END { exit found ? 0 : 1 }
' "$PRESET_PATH"; then
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

if ! /usr/libexec/PlistBuddy -c 'Print :NSHealthUpdateUsageDescription' "$APP_PATH/Info.plist" >/dev/null; then
	echo "ERROR: Export succeeded, but Info.plist has no HealthKit update explanation required by App Store validation." >&2
	exit 1
fi

if ! grep -Fq 'StepCounterPlugin' "$EXPORT_DIR/DragosTimeToShine/dummy.cpp"; then
	echo "ERROR: Export succeeded, but StepCounterPlugin was not registered." >&2
	exit 1
fi

GODOT_SIM_LIBRARY="$EXPORT_DIR/DragosTimeToShine.xcframework/ios-arm64_x86_64-simulator/libgodot.a"
PLUGIN_SIM_LIBRARY="$EXPORT_DIR/DragosTimeToShine/dylibs/ios/plugins/step_counter/StepCounterPlugin.xcframework/ios-arm64-simulator/libStepCounterPlugin.a"

for library in "$GODOT_SIM_LIBRARY" "$PLUGIN_SIM_LIBRARY"; do
	if [ ! -f "$library" ] || ! lipo -archs "$library" | grep -qw arm64; then
		echo "ERROR: Exported Simulator library is missing arm64: $library" >&2
		exit 1
	fi
done

for framework in UIKit QuartzCore Metal IOSurface CoreVideo CoreGraphics AudioToolbox AVFoundation CoreMotion GameController Security HealthKit; do
	if ! grep -Fq "$framework.framework" "$EXPORT_DIR/DragosTimeToShine.xcodeproj/project.pbxproj"; then
		echo "ERROR: Exported Xcode project does not link $framework.framework." >&2
		exit 1
	fi
done

if grep -Fq -- '-Wl,-u,_main' "$EXPORT_DIR/DragosTimeToShine.xcodeproj/project.pbxproj"; then
	echo "ERROR: Exported Xcode project still contains the obsolete forced _main flag." >&2
	exit 1
fi

SIMULATOR_DERIVED_DATA="$TEMPLATE_CHECK_DIR/DerivedData"
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
	-project "$EXPORT_DIR/DragosTimeToShine.xcodeproj" \
	-scheme DragosTimeToShine \
	-configuration "$(printf '%s' "$EXPORT_MODE" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')" \
	-sdk iphonesimulator \
	-destination "generic/platform=iOS Simulator" \
	-derivedDataPath "$SIMULATOR_DERIVED_DATA" \
	CODE_SIGNING_ALLOWED=NO \
	build

echo "Validated iOS export: $IPA_PATH"
echo "Validated arm64 device archive and arm64 Simulator build."
echo "HealthKit entitlement, read/update privacy text, native plugin, and Apple frameworks are present."
