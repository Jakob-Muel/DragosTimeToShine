extends RefCounted

const VERSION := "v0.1"

## Developer tools such as the Dragon Lab are shown only in debug builds (editor runs and
## debug exports), never in release builds for players. Tests can force the value:
## -1 = automatic, 0 = hidden, 1 = shown.
static var dev_tools_override := -1


static func dev_tools_enabled() -> bool:
	if dev_tools_override >= 0:
		return dev_tools_override == 1
	return OS.is_debug_build()
