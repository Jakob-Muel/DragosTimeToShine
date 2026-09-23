extends SceneTree

## Crash-safe saving: checksums, backup rotation, recovery and quarantine.
## Uses its own files under user://test_saves/, never the player's save.

const DIR := "user://test_saves"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_clean()
	_test_round_trip_and_backup()
	_clean()
	_test_truncated_main_recovers_from_backup()
	_clean()
	_test_checksum_rejects_edits()
	_clean()
	_test_crash_between_renames_uses_temp()
	_clean()
	_test_partial_temp_is_ignored()
	_clean()
	_test_legacy_plain_json_loads()
	_clean()
	_test_nothing_usable_keeps_damaged_file()
	_clean()
	_test_delete_all()
	_clean()
	await _test_game_state_integration()
	_clean()
	print("Save repository test: valid")
	quit()


func _repo(name := "save.json") -> SaveRepository:
	return SaveRepository.new("%s/%s" % [DIR, name])


func _test_round_trip_and_backup() -> void:
	var repo := _repo()
	assert(repo.write({"gold": 1}) == OK, "First write must succeed.")
	assert(not FileAccess.file_exists(repo.backup_path()), "No backup before a second save.")
	assert(not FileAccess.file_exists(repo.temp_path()), "Temp file must be moved into place.")
	assert(_text(repo.path).contains(SaveRepository.CHECKSUM_PREFIX), "Saves carry a checksum.")
	assert(repo.write({"gold": 2}) == OK, "Second write must succeed.")
	var result := repo.read()
	assert(result["source"] == "main" and int(result["payload"]["gold"]) == 2, "Main has the latest state.")
	assert(not result["recovered"], "A healthy save is not a recovery.")
	var backup := SaveRepository.parse(_text(repo.backup_path()))
	assert(int(backup["gold"]) == 1, "Backup holds the previous state.")


func _test_truncated_main_recovers_from_backup() -> void:
	var repo := _repo()
	repo.write({"gold": 1})
	repo.write({"gold": 2})
	var text := _text(repo.path)
	_write_raw(repo.path, text.substr(0, text.length() / 2))
	var result := repo.read()
	assert(result["source"] == "backup" and result["recovered"], "Truncated main falls back to backup.")
	assert(int(result["payload"]["gold"]) == 1, "Backup content is returned.")
	assert(not String(result["corrupt_path"]).is_empty(), "Damaged main is quarantined.")
	assert(FileAccess.file_exists(result["corrupt_path"]), "Quarantined file is kept for recovery.")
	assert(not FileAccess.file_exists(repo.path), "Damaged main is moved, not left in place.")


func _test_checksum_rejects_edits() -> void:
	var repo := _repo()
	repo.write({"gold": 1})
	repo.write({"gold": 2})
	_write_raw(repo.path, _text(repo.path).replace("\"gold\":2", "\"gold\":9"))
	var result := repo.read()
	assert(result["source"] == "backup", "An edited file fails its checksum.")
	assert(SaveRepository.parse("{\"a\":1}\n#sha256:deadbeef").is_empty(), "Wrong checksum is rejected.")
	assert(SaveRepository.parse("[1, 2]").is_empty(), "Non-object JSON is rejected.")


func _test_crash_between_renames_uses_temp() -> void:
	var repo := _repo()
	repo.write({"gold": 1})
	repo.write({"gold": 2})
	# Simulate a crash after the old save became the backup but before the new temp
	# file was moved into place: main is missing, temp holds the newest state.
	DirAccess.rename_absolute(_global(repo.path), _global(repo.temp_path()))
	var result := repo.read()
	assert(result["source"] == "temp" and int(result["payload"]["gold"]) == 2, "Complete temp file wins.")
	assert(result["recovered"], "Loading from temp counts as a recovery.")


func _test_partial_temp_is_ignored() -> void:
	var repo := _repo()
	repo.write({"gold": 3})
	_write_raw(repo.temp_path(), "{\"gold\": 4")
	var result := repo.read()
	assert(result["source"] == "main" and int(result["payload"]["gold"]) == 3, "A partial temp never beats a valid main.")
	assert(repo.write({"gold": 5}) == OK, "A stale temp file does not block the next save.")
	assert(int(repo.read()["payload"]["gold"]) == 5, "The next save replaces the stale temp file.")


func _test_legacy_plain_json_loads() -> void:
	var repo := _repo()
	_write_raw(repo.path, JSON.stringify({"schema_version": 11, "gold": 7}))
	var result := repo.read()
	assert(result["source"] == "main" and int(result["payload"]["gold"]) == 7, "Saves without a checksum still load.")


func _test_nothing_usable_keeps_damaged_file() -> void:
	var repo := _repo()
	_write_raw(repo.path, "not json at all")
	var result := repo.read()
	assert(result["source"] == "none" and (result["payload"] as Dictionary).is_empty(), "Nothing usable yields no payload.")
	assert(FileAccess.file_exists(result["corrupt_path"]), "The damaged file is kept, never deleted.")


func _test_delete_all() -> void:
	var repo := _repo()
	repo.write({"gold": 1})
	repo.write({"gold": 2})
	_write_raw(repo.temp_path(), "leftover")
	assert(repo.exists(), "Files exist before deletion.")
	assert(repo.delete_all() == OK, "Delete succeeds.")
	assert(not repo.exists(), "Main, temp and backup are removed.")


func _test_game_state_integration() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.reset_for_tests()
	game_state.persistence_enabled = true
	game_state.save_repository = _repo("game_state.json")
	game_state.gold = 4
	game_state.save_game()
	game_state.gold = 6
	game_state.save_game()
	var repo: SaveRepository = game_state.save_repository
	_write_raw(repo.path, "{\"truncated\": ")
	game_state.gold = 0
	game_state.load_game()
	assert(game_state.last_load_report["source"] == "backup", "GameState recovers from the backup.")
	assert(game_state.gold == 4, "Recovered state is applied.")
	var healed := SaveRepository.parse(_text(repo.path))
	assert(int(healed["currencies"]["gold"]) == 4, "Recovery immediately rewrites a valid main save.")
	game_state.reset_app()
	assert(not repo.exists(), "Reset removes main, temp and backup files.")
	game_state.persistence_enabled = false
	game_state.save_repository = SaveRepository.new(game_state.SAVE_PATH)
	await process_frame


func _text(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _write_raw(file_path: String, content: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


func _global(file_path: String) -> String:
	return ProjectSettings.globalize_path(file_path)


func _clean() -> void:
	var directory := _global(DIR)
	if DirAccess.dir_exists_absolute(directory):
		for file_name: String in DirAccess.get_files_at(directory):
			DirAccess.remove_absolute(directory.path_join(file_name))
	else:
		DirAccess.make_dir_recursive_absolute(directory)
