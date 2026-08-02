#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.6.1"
GODOT_TEMPLATE_VERSION="${GODOT_VERSION}.stable"
GODOT_RELEASE_LABEL="${GODOT_VERSION}-stable"
GODOT_SOURCE_SHA256="92ad1898ba8086640eb66ae9949ee8694de5c691d373febcd0d7f1f5cd098f62"
GODOT_SOURCE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_RELEASE_LABEL}/godot-${GODOT_RELEASE_LABEL}.tar.xz"
SCONS_VERSION="4.10.1"
BUILD_JOBS="${BUILD_JOBS:-8}"
GODOT_BIN_PATH="${GODOT_BIN_PATH:-/Applications/Godot.app/Contents/MacOS/Godot}"
TEMPLATE_ROOT="${GODOT_TEMPLATE_ROOT:-$HOME/Library/Application Support/Godot/export_templates}"
TEMPLATE_DIR="$TEMPLATE_ROOT/$GODOT_TEMPLATE_VERSION"
IOS_TEMPLATE="$TEMPLATE_DIR/ios.zip"
BACKUP_TEMPLATE="$TEMPLATE_DIR/ios.official-x86_64-only.zip"
WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dragos-ios-template.XXXXXX")"
SOURCE_ARCHIVE="$WORK_ROOT/godot-source.tar.xz"
SOURCE_DIR="$WORK_ROOT/godot-source"
PAYLOAD_DIR="$WORK_ROOT/ios-template"
VENV_DIR="$WORK_ROOT/venv"
DEBUG_ARM64="$WORK_ROOT/libgodot.debug.arm64.simulator.a"
RELEASE_ARM64="$WORK_ROOT/libgodot.release.arm64.simulator.a"
REPAIRED_TEMPLATE="$WORK_ROOT/ios.repaired.zip"

cleanup() {
	rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

for command_name in curl python3 shasum tar unzip zip lipo xcrun; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		echo "ERROR: Required command is missing: $command_name" >&2
		exit 1
	fi
done

if [[ ! -f "$IOS_TEMPLATE" ]]; then
	echo "ERROR: Install the official Godot $GODOT_VERSION export templates first." >&2
	echo "Expected: $IOS_TEMPLATE" >&2
	exit 1
fi

if [[ "$("$GODOT_BIN_PATH" --version 2>/dev/null || true)" != "$GODOT_VERSION."* ]]; then
	echo "ERROR: $GODOT_BIN_PATH is not Godot $GODOT_VERSION." >&2
	exit 1
fi

already_repaired=true
for configuration in debug release; do
	current_library="$WORK_ROOT/libgodot.$configuration.current.a"
	if ! unzip -p "$IOS_TEMPLATE" \
		"libgodot.ios.$configuration.xcframework/ios-arm64_x86_64-simulator/libgodot.a" \
		> "$current_library"; then
		already_repaired=false
		break
	fi
	if ! lipo -archs "$current_library" | grep -qw arm64; then
		already_repaired=false
		break
	fi
done

if [[ "$already_repaired" == true ]]; then
	echo "Godot $GODOT_VERSION iOS template already supports arm64 Simulator builds."
	exit 0
fi

echo "Downloading verified Godot $GODOT_VERSION source..."
curl -L --fail --silent --show-error "$GODOT_SOURCE_URL" -o "$SOURCE_ARCHIVE"
if [[ "$(shasum -a 256 "$SOURCE_ARCHIVE" | awk '{print $1}')" != "$GODOT_SOURCE_SHA256" ]]; then
	echo "ERROR: Godot source checksum does not match." >&2
	exit 1
fi

mkdir -p "$SOURCE_DIR"
tar -xJf "$SOURCE_ARCHIVE" -C "$SOURCE_DIR" --strip-components=1
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --quiet "scons==$SCONS_VERSION"

echo "Building the Godot arm64 debug Simulator slice..."
(
	cd "$SOURCE_DIR"
	"$VENV_DIR/bin/scons" platform=ios target=template_debug ios_simulator=yes arch=arm64 -j"$BUILD_JOBS"
)
cp "$SOURCE_DIR/bin/libgodot.ios.template_debug.arm64.simulator.a" "$DEBUG_ARM64"

echo "Cleaning debug objects before the release build..."
(
	cd "$SOURCE_DIR"
	"$VENV_DIR/bin/scons" -c platform=ios target=template_debug ios_simulator=yes arch=arm64 -j"$BUILD_JOBS" >/dev/null
)

echo "Building the Godot arm64 release Simulator slice..."
(
	cd "$SOURCE_DIR"
	"$VENV_DIR/bin/scons" platform=ios target=template_release ios_simulator=yes arch=arm64 -j"$BUILD_JOBS"
)
cp "$SOURCE_DIR/bin/libgodot.ios.template_release.arm64.simulator.a" "$RELEASE_ARM64"

mkdir -p "$PAYLOAD_DIR"
unzip -q "$IOS_TEMPLATE" -d "$PAYLOAD_DIR"

DEBUG_FAT="$PAYLOAD_DIR/libgodot.ios.debug.xcframework/ios-arm64_x86_64-simulator/libgodot.a"
RELEASE_FAT="$PAYLOAD_DIR/libgodot.ios.release.xcframework/ios-arm64_x86_64-simulator/libgodot.a"

lipo -create "$DEBUG_FAT" "$DEBUG_ARM64" -output "$WORK_ROOT/debug.fat.a"
mv "$WORK_ROOT/debug.fat.a" "$DEBUG_FAT"
lipo -create "$RELEASE_FAT" "$RELEASE_ARM64" -output "$WORK_ROOT/release.fat.a"
mv "$WORK_ROOT/release.fat.a" "$RELEASE_FAT"

for library in "$DEBUG_FAT" "$RELEASE_FAT"; do
	architectures="$(lipo -archs "$library")"
	if [[ " $architectures " != *" arm64 "* || " $architectures " != *" x86_64 "* ]]; then
		echo "ERROR: Repaired library has unexpected architectures: $architectures" >&2
		exit 1
	fi
done

(
	cd "$PAYLOAD_DIR"
	zip -qry "$REPAIRED_TEMPLATE" .
)
unzip -tq "$REPAIRED_TEMPLATE"

cp -n "$IOS_TEMPLATE" "$BACKUP_TEMPLATE"
cp "$REPAIRED_TEMPLATE" "$IOS_TEMPLATE.repaired"
mv "$IOS_TEMPLATE.repaired" "$IOS_TEMPLATE"

echo "Installed repaired template: $IOS_TEMPLATE"
echo "Preserved official template: $BACKUP_TEMPLATE"
echo "Godot's normal iOS Export button now supports arm64 Simulator builds."
