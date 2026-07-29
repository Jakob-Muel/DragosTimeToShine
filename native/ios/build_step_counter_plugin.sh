#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
	echo "Usage: $0 /path/to/godot-4.6.1-source [output-directory]"
	exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GODOT_SOURCE="$1"
OUTPUT_DIR="${2:-$PROJECT_ROOT/ios/plugins/step_counter}"
PLUGIN_SOURCE="$SCRIPT_DIR/plugin"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dragos-step-plugin.XXXXXX")"
MODULE_CACHE="$BUILD_ROOT/module-cache"

required_headers=(
	"core/object/gdvirtual.gen.inc"
	"core/version_generated.gen.h"
	"core/disabled_classes.gen.h"
	"modules/modules_enabled.gen.h"
	"core/extension/gdextension_interface.gen.h"
	"core/extension/ext_wrappers.gen.inc"
)

for header in "${required_headers[@]}"; do
	if [[ ! -f "$GODOT_SOURCE/$header" ]]; then
		echo "Missing generated Godot header: $GODOT_SOURCE/$header"
		echo "Generate the 4.6.1 iOS headers with SCons before running this script."
		exit 66
	fi
done

if [[ -d "$OUTPUT_DIR/StepCounterPlugin.debug.xcframework" ||
		-d "$OUTPUT_DIR/StepCounterPlugin.release.xcframework" ]]; then
	echo "Output XCFramework already exists in $OUTPUT_DIR"
	echo "Choose an empty output directory or move the existing generated frameworks first."
	exit 73
fi

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"

DEVICE_SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
SIMULATOR_SDK_PATH="$(xcrun --sdk iphonesimulator --show-sdk-path)"

build_slice() {
	local configuration="$1"
	local sdk="$2"
	local target="$3"
	local sdk_path="$4"
	local slice_dir="$BUILD_ROOT/$configuration-$sdk"
	local debug_define=()

	if [[ "$configuration" == "debug" ]]; then
		debug_define=(-DDEBUG_ENABLED)
	fi

	mkdir -p "$slice_dir"
	xcrun --sdk "$sdk" clang++ \
		-std=gnu++17 -target "$target" -isysroot "$sdk_path" \
		-fobjc-arc -fmodules -fcxx-modules -fblocks -fno-exceptions \
		-fvisibility=hidden -DPTRCALL_ENABLED -DIOS_ENABLED -DUNIX_ENABLED \
		"${debug_define[@]}" \
		-I"$GODOT_SOURCE" -I"$GODOT_SOURCE/platform/ios" \
		-c "$PLUGIN_SOURCE/step_counter_plugin.mm" \
		-o "$slice_dir/step_counter_plugin.o"
	xcrun --sdk "$sdk" clang++ \
		-std=gnu++17 -target "$target" -isysroot "$sdk_path" \
		-fmodules -fcxx-modules -fblocks -fno-exceptions \
		-fvisibility=hidden -DPTRCALL_ENABLED -DIOS_ENABLED -DUNIX_ENABLED \
		"${debug_define[@]}" \
		-I"$GODOT_SOURCE" -I"$GODOT_SOURCE/platform/ios" \
		-c "$PLUGIN_SOURCE/step_counter_module.cpp" \
		-o "$slice_dir/step_counter_module.o"
	xcrun --sdk "$sdk" ar rcs "$slice_dir/libStepCounterPlugin.a" \
		"$slice_dir/step_counter_plugin.o" "$slice_dir/step_counter_module.o"
}

build_slice debug iphoneos arm64-apple-ios17.0 "$DEVICE_SDK_PATH"
build_slice debug iphonesimulator arm64-apple-ios17.0-simulator "$SIMULATOR_SDK_PATH"
build_slice release iphoneos arm64-apple-ios17.0 "$DEVICE_SDK_PATH"
build_slice release iphonesimulator arm64-apple-ios17.0-simulator "$SIMULATOR_SDK_PATH"

xcodebuild -create-xcframework \
	-library "$BUILD_ROOT/debug-iphoneos/libStepCounterPlugin.a" \
	-library "$BUILD_ROOT/debug-iphonesimulator/libStepCounterPlugin.a" \
	-output "$OUTPUT_DIR/StepCounterPlugin.debug.xcframework"
xcodebuild -create-xcframework \
	-library "$BUILD_ROOT/release-iphoneos/libStepCounterPlugin.a" \
	-library "$BUILD_ROOT/release-iphonesimulator/libStepCounterPlugin.a" \
	-output "$OUTPUT_DIR/StepCounterPlugin.release.xcframework"

echo "Built StepCounterPlugin XCFrameworks in $OUTPUT_DIR"
echo "Intermediate build files remain in $BUILD_ROOT"
