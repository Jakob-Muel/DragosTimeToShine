class_name SaveRepository
extends RefCounted

## Crash-safe JSON persistence for the game state. Pure file I/O: no game rules.
##
## Write: serialize to `<path>.tmp`, flush and close, move the current save to
## `<path>.bak`, then move the temp file into place. Every file carries a SHA-256 footer,
## so a truncated or hand-damaged file is detected instead of trusted.
##
## Read: the first valid file wins, in the order main, temp, backup. A damaged main save
## is never overwritten: it is moved aside to `<path>.corrupt-<unix time>` for recovery.
## Files written before this format (plain JSON without footer) still load.

const CHECKSUM_PREFIX := "\n#sha256:"

var path: String


func _init(save_path: String) -> void:
	path = save_path


func temp_path() -> String:
	return path + ".tmp"


func backup_path() -> String:
	return path + ".bak"


func exists() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(temp_path()) \
		or FileAccess.file_exists(backup_path())


## Returns OK or the first error. On failure the previous save stays untouched.
func write(state: Dictionary) -> Error:
	var text := JSON.stringify(state)
	var content := text + CHECKSUM_PREFIX + text.sha256_text()
	_ensure_directory()
	var file := FileAccess.open(temp_path(), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	if _read_valid(temp_path()).is_empty():
		return ERR_FILE_CORRUPT
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path()):
			DirAccess.remove_absolute(_global(backup_path()))
		var backup_error := DirAccess.rename_absolute(_global(path), _global(backup_path()))
		if backup_error != OK:
			return backup_error
	return DirAccess.rename_absolute(_global(temp_path()), _global(path))


## Returns {"payload": Dictionary, "source": "main"|"temp"|"backup"|"none",
## "recovered": bool, "corrupt_path": String}.
func read() -> Dictionary:
	var result := {"payload": {}, "source": "none", "recovered": false, "corrupt_path": ""}
	var main_exists := FileAccess.file_exists(path)
	var payload := _read_valid(path)
	if not payload.is_empty():
		result["payload"] = payload
		result["source"] = "main"
		return result
	if main_exists:
		result["corrupt_path"] = _quarantine(path)
	for candidate: Array in [[temp_path(), "temp"], [backup_path(), "backup"]]:
		payload = _read_valid(candidate[0])
		if not payload.is_empty():
			result["payload"] = payload
			result["source"] = candidate[1]
			result["recovered"] = true
			return result
	return result


## Removes the save, its temp file and its backup. Quarantined files are kept.
func delete_all() -> Error:
	var first_error := OK
	for file_path: String in [path, temp_path(), backup_path()]:
		if FileAccess.file_exists(file_path):
			var error := DirAccess.remove_absolute(_global(file_path))
			if error != OK and first_error == OK:
				first_error = error
	return first_error


## Parses one file. Returns an empty Dictionary when missing, damaged or not an object.
static func parse(content: String) -> Dictionary:
	var text := content
	var marker := content.rfind(CHECKSUM_PREFIX)
	if marker >= 0:
		text = content.substr(0, marker)
		var expected := content.substr(marker + CHECKSUM_PREFIX.length()).strip_edges()
		if text.sha256_text() != expected:
			return {}
	# JSON.new().parse() reports failures through its return value instead of logging an
	# engine error, which keeps expected damage (truncation) out of the error log.
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	return json.data if json.data is Dictionary else {}


func _read_valid(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	return parse(file.get_as_text())


func _quarantine(file_path: String) -> String:
	var target := "%s.corrupt-%d" % [path, int(Time.get_unix_time_from_system())]
	if DirAccess.rename_absolute(_global(file_path), _global(target)) != OK:
		return ""
	push_warning("Damaged save moved to %s" % target)
	return target


func _ensure_directory() -> void:
	var directory := _global(path).get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)


func _global(file_path: String) -> String:
	return ProjectSettings.globalize_path(file_path)
