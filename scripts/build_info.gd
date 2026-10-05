extends RefCounted

const VERSION := "v0.1"

## Developer tools such as the Dragon Lab are on by default in debug builds (editor runs and
## debug exports) and off in release builds (TestFlight, store). Tapping the version label
## on the main menu UNLOCK_TAPS times in quick succession flips them on or off on this
## device; the choice is stored in DEV_TOOLS_PATH and wins over the build default.
## Tests can force the value: -1 = automatic, 0 = hidden, 1 = shown.
static var dev_tools_override := -1

const DEV_TOOLS_PATH := "user://dev_tools.cfg"
const UNLOCK_TAPS := 7
## Maximum gap between two taps of the unlock gesture.
const UNLOCK_TAP_GAP_MS := 700

## -2 = not loaded yet, -1 = no device choice, 0 = off, 1 = on.
static var _device_choice := -2
static var _tap_count := 0
static var _last_tap_ms := -100000


static func dev_tools_enabled() -> bool:
	if dev_tools_override >= 0:
		return dev_tools_override == 1
	var choice := _stored_choice()
	if choice >= 0:
		return choice == 1
	return OS.is_debug_build()


static func set_dev_tools_enabled(enabled: bool) -> void:
	if dev_tools_override >= 0:
		dev_tools_override = 1 if enabled else 0
		return
	_device_choice = 1 if enabled else 0
	if not _persistence_allowed():
		return
	var config := ConfigFile.new()
	config.set_value("dev_tools", "enabled", enabled)
	var error := config.save(DEV_TOOLS_PATH)
	if error != OK:
		push_warning("Could not store the dev tools choice (error %d)." % error)


static func toggle_dev_tools() -> bool:
	set_dev_tools_enabled(not dev_tools_enabled())
	return dev_tools_enabled()


## Counts one tap of the unlock gesture. Returns true when this tap completed the
## gesture and dev tools were toggled.
static func register_unlock_tap(now_ms: int = -1) -> bool:
	if now_ms < 0:
		now_ms = Time.get_ticks_msec()
	if now_ms - _last_tap_ms > UNLOCK_TAP_GAP_MS:
		_tap_count = 0
	_last_tap_ms = now_ms
	_tap_count += 1
	if _tap_count < UNLOCK_TAPS:
		return false
	_tap_count = 0
	_last_tap_ms = -100000
	toggle_dev_tools()
	return true


## Forgets the device choice and the gesture progress (tests only, never touches disk).
static func reset_for_tests() -> void:
	dev_tools_override = -1
	_device_choice = -1
	_tap_count = 0
	_last_tap_ms = -100000


static func _stored_choice() -> int:
	if _device_choice != -2:
		return _device_choice
	_device_choice = -1
	if not _persistence_allowed():
		return _device_choice
	var config := ConfigFile.new()
	if config.load(DEV_TOOLS_PATH) == OK:
		var value: Variant = config.get_value("dev_tools", "enabled", null)
		if value is bool:
			_device_choice = 1 if value else 0
	return _device_choice


## Test and tool runs (--script) never read or write the device choice.
static func _persistence_allowed() -> bool:
	var args := OS.get_cmdline_args()
	return not (args.has("--script") or args.has("-s"))
