extends Node

signal state_changed

const SAVE_PATH := "user://dragos_save.json"
const DRAGON_CAPACITY := 12
const EGG_REQUIRED_STEPS := 1000
const EGG_PRICE_GOLD := 1
const FLIGHT_XP_PER_LEVEL := 10
const FLIGHT_CONTEST_LEVEL := 5
const FLIGHT_METERS_PER_LEVEL := 10

var hunger := 42
var cleanliness := 28.0
var care_points := 18
var gems := 125
var gold := 0
var dragons: Array[Dictionary] = []
var eggs: Array[Dictionary] = []
var persistence_enabled := true


func _ready() -> void:
	_reset_defaults()
	load_game()


func _reset_defaults() -> void:
	hunger = 42
	cleanliness = 28.0
	care_points = 18
	gems = 125
	gold = 0
	dragons = [{
		"id": "luma",
		"name_key": "DRAGON_NAME",
		"species": "sunwing",
		"starter": true,
		"flight_xp": 0,
	}]
	eggs = []


func save_game() -> void:
	if not persistence_enabled:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save game state.")
		return
	var payload := {
		"hunger": hunger,
		"cleanliness": cleanliness,
		"care_points": care_points,
		"gems": gems,
		"gold": gold,
		"dragons": dragons,
		"eggs": eggs,
	}
	file.store_string(JSON.stringify(payload))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Ignoring invalid saved game state.")
		return
	hunger = clampi(int(parsed.get("hunger", hunger)), 0, 100)
	cleanliness = clampf(float(parsed.get("cleanliness", cleanliness)), 0.0, 100.0)
	care_points = maxi(0, int(parsed.get("care_points", care_points)))
	gems = maxi(0, int(parsed.get("gems", gems)))
	gold = maxi(0, int(parsed.get("gold", gold)))
	var saved_dragons: Variant = parsed.get("dragons", dragons)
	if saved_dragons is Array and not saved_dragons.is_empty():
		dragons.assign(saved_dragons)
	var saved_eggs: Variant = parsed.get("eggs", eggs)
	if saved_eggs is Array:
		eggs.assign(saved_eggs)


func purchase_egg(kind: String = "ice") -> String:
	if gold < EGG_PRICE_GOLD or eggs.size() + dragons.size() >= DRAGON_CAPACITY:
		return ""
	gold -= EGG_PRICE_GOLD
	var egg_id := _append_egg(kind)
	_commit_change()
	return egg_id


func _append_egg(kind: String) -> String:
	var egg_id := "egg-%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	eggs.append({
		"id": egg_id,
		"kind": kind,
		"required_steps": EGG_REQUIRED_STEPS,
		"progress_steps": 0,
		"incubation_start": 0,
		"mock_baseline": 0,
	})
	return egg_id


func get_dragon(dragon_id: String) -> Dictionary:
	for dragon in dragons:
		if String(dragon.get("id", "")) == dragon_id:
			return dragon
	return {}


func get_flight_xp(dragon_id: String) -> int:
	return maxi(0, int(get_dragon(dragon_id).get("flight_xp", 0)))


func get_flight_level(dragon_id: String) -> int:
	return get_flight_xp(dragon_id) / FLIGHT_XP_PER_LEVEL


func add_flight_xp(dragon_id: String, amount: int) -> void:
	if amount <= 0:
		return
	for index in dragons.size():
		if String(dragons[index].get("id", "")) != dragon_id:
			continue
		var dragon := dragons[index]
		dragon["flight_xp"] = maxi(0, int(dragon.get("flight_xp", 0))) + amount
		dragons[index] = dragon
		_commit_change()
		return


func can_enter_flight_contest(dragon_id: String) -> bool:
	return get_flight_level(dragon_id) >= FLIGHT_CONTEST_LEVEL


func flight_contest_distance(dragon_id: String) -> int:
	return get_flight_level(dragon_id) * FLIGHT_METERS_PER_LEVEL


func complete_flight_contest(dragon_id: String) -> int:
	var distance := flight_contest_distance(dragon_id)
	if distance < FLIGHT_CONTEST_LEVEL * FLIGHT_METERS_PER_LEVEL:
		return 0
	gold += 1
	_commit_change()
	return 1


func get_egg(egg_id: String) -> Dictionary:
	for egg in eggs:
		if String(egg.get("id", "")) == egg_id:
			return egg
	return {}


func start_incubation(egg_id: String, mock_baseline: int) -> void:
	for index in eggs.size():
		if String(eggs[index].get("id", "")) != egg_id:
			continue
		var egg := eggs[index]
		if int(egg.get("incubation_start", 0)) == 0:
			egg["incubation_start"] = int(Time.get_unix_time_from_system())
			egg["mock_baseline"] = mock_baseline
			egg["progress_steps"] = 0
			eggs[index] = egg
			_commit_change()
		return


func update_egg_progress(egg_id: String, steps: int) -> void:
	for index in eggs.size():
		if String(eggs[index].get("id", "")) != egg_id:
			continue
		var egg := eggs[index]
		var previous := int(egg.get("progress_steps", 0))
		var required := int(egg.get("required_steps", EGG_REQUIRED_STEPS))
		egg["progress_steps"] = clampi(maxi(previous, steps), 0, required)
		eggs[index] = egg
		if int(egg["progress_steps"]) != previous:
			_commit_change()
		return


func can_hatch(egg_id: String) -> bool:
	var egg := get_egg(egg_id)
	if egg.is_empty():
		return false
	return int(egg.get("progress_steps", 0)) >= int(egg.get("required_steps", EGG_REQUIRED_STEPS))


func hatch_egg(egg_id: String) -> bool:
	if not can_hatch(egg_id) or dragons.size() >= DRAGON_CAPACITY:
		return false
	for index in eggs.size():
		if String(eggs[index].get("id", "")) != egg_id:
			continue
		var egg_kind := String(eggs[index].get("kind", "sunwing"))
		eggs.remove_at(index)
		dragons.append({
			"id": "dragon-%d" % Time.get_unix_time_from_system(),
			"name_key": "ICE_DRAGON_NAME" if egg_kind == "ice" else "HATCHED_DRAGON_NAME",
			"species": "ice" if egg_kind == "ice" else "sunwing",
			"starter": false,
			"flight_xp": 0,
		})
		_commit_change()
		return true
	return false


func _commit_change() -> void:
	if persistence_enabled:
		save_game()
	state_changed.emit()


func reset_for_tests() -> void:
	persistence_enabled = false
	_reset_defaults()
	state_changed.emit()
