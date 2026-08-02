extends Node

signal state_changed

const SAVE_PATH := "user://dragos_save.json"
const SAVE_SCHEMA_VERSION := 6
const DRAGON_CAPACITY := 12
const EGG_REQUIRED_STEPS := 1000
const FUSION_EGG_REQUIRED_STEPS := 5000
const EGG_PRICE_GOLD := 1
const SHOP_EGG_KINDS: Array[StringName] = [&"fire", &"water", &"earth"]
const FLIGHT_CATEGORY := &"flight"
const FLIGHT_XP_PER_LEVEL := 10
const FLIGHT_CONTEST_LEVEL := 5
const FLIGHT_METERS_PER_LEVEL := 10
const FLIGHT_CONTEST_GOALS := [50, 70, 100]

const DEFAULT_HUNGER := 42
const DEFAULT_CLEANLINESS := 28.0
const DEFAULT_CARE_POINTS := 18
const DEFAULT_FUSION_STARS := 3

var gems := 125
var gold := 0
var fusion_stars := 0
var dragons: Array[Dictionary] = []
var eggs: Array[Dictionary] = []
var persistence_enabled := true

var catalog := GameCatalog.new()
var collection := CollectionService.new(catalog)
var fusion := FusionService.new(catalog, collection)


func _ready() -> void:
	_reset_defaults()
	load_game()


func _reset_defaults() -> void:
	gems = 125
	gold = 0
	fusion_stars = DEFAULT_FUSION_STARS
	dragons = [
		_new_dragon(
			&"luma",
			"luma",
			true,
			DEFAULT_HUNGER,
			DEFAULT_CLEANLINESS,
			DEFAULT_CARE_POINTS
		)
	]
	eggs = []


func _new_dragon(
	definition_id: StringName,
	instance_id: String = "",
	starter := false,
	hunger := DEFAULT_HUNGER,
	cleanliness := DEFAULT_CLEANLINESS,
	care_points := 0
) -> Dictionary:
	if instance_id.is_empty():
		instance_id = "dragon-%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	return {
		"id": instance_id,
		"definition_id": String(definition_id),
		"starter": starter,
		"hunger": clampi(hunger, 0, 100),
		"cleanliness": clampf(cleanliness, 0.0, 100.0),
		"care_points": maxi(0, care_points),
		"training_xp": {String(FLIGHT_CATEGORY): 0},
		"flight_contest_wins": 0,
	}


func serialize_state() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"currencies": {
			"gems": gems,
			"gold": gold,
			"fusion_stars": fusion_stars,
		},
		"dragons": dragons.duplicate(true),
		"eggs": eggs.duplicate(true),
	}


func save_game() -> void:
	if not persistence_enabled:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save game state.")
		return
	file.store_string(JSON.stringify(serialize_state()))


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
	load_payload(parsed)


func load_payload(payload: Dictionary) -> void:
	var version := int(payload.get("schema_version", 1))
	var should_resave := version < SAVE_SCHEMA_VERSION
	var removed_duplicate_types := false
	var currencies: Variant = payload.get("currencies", {})
	if version >= 2 and currencies is Dictionary:
		gems = maxi(0, int(currencies.get("gems", gems)))
		gold = maxi(0, int(currencies.get("gold", gold)))
		fusion_stars = maxi(0, int(currencies.get("fusion_stars", fusion_stars)))
	else:
		gems = maxi(0, int(payload.get("gems", gems)))
		gold = maxi(0, int(payload.get("gold", gold)))
		fusion_stars = maxi(0, int(payload.get("fusion_stars", 0)))
	if version < 3:
		fusion_stars = maxi(DEFAULT_FUSION_STARS, fusion_stars)
	elif version < 5:
		fusion_stars += 2

	var legacy_care := {
		"hunger": clampi(int(payload.get("hunger", DEFAULT_HUNGER)), 0, 100),
		"cleanliness": clampf(float(payload.get("cleanliness", DEFAULT_CLEANLINESS)), 0.0, 100.0),
		"care_points": maxi(0, int(payload.get("care_points", DEFAULT_CARE_POINTS))),
	}
	var saved_dragons: Variant = payload.get("dragons", [])
	var normalized_dragons: Array[Dictionary] = []
	var dragon_indexes_by_type: Dictionary = {}
	if saved_dragons is Array:
		for value: Variant in saved_dragons:
			if value is Dictionary:
				var normalized := _normalize_dragon(value, legacy_care)
				if normalized.is_empty():
					continue
				var type_key := _dragon_type_key(normalized)
				if dragon_indexes_by_type.has(type_key):
					var existing_index := int(dragon_indexes_by_type[type_key])
					normalized_dragons[existing_index] = _merge_duplicate_dragons(
						normalized_dragons[existing_index],
						normalized
					)
					removed_duplicate_types = true
					should_resave = true
					continue
				dragon_indexes_by_type[type_key] = normalized_dragons.size()
				normalized_dragons.append(normalized)
	if not normalized_dragons.is_empty():
		dragons = normalized_dragons

	var saved_eggs: Variant = payload.get("eggs", [])
	var normalized_eggs: Array[Dictionary] = []
	var reserved_type_keys: Dictionary = {}
	for dragon: Dictionary in dragons:
		reserved_type_keys[_dragon_type_key(dragon)] = true
	if saved_eggs is Array:
		for value: Variant in saved_eggs:
			if value is Dictionary:
				var normalized := _normalize_egg(value)
				if normalized.is_empty():
					continue
				var type_key := _definition_type_key(
					StringName(String(normalized.get("definition_id", "")))
				)
				if reserved_type_keys.has(type_key):
					removed_duplicate_types = true
					should_resave = true
					continue
				reserved_type_keys[type_key] = true
				normalized_eggs.append(normalized)
	eggs = normalized_eggs
	if version < 4 and _migrate_direct_voltara_to_fusion_egg():
		should_resave = true
	if removed_duplicate_types:
		push_warning("Removed duplicate dragon types from the saved game.")
	if should_resave:
		save_game()


func _migrate_direct_voltara_to_fusion_egg() -> bool:
	var removed_voltara := false
	for index in range(dragons.size() - 1, -1, -1):
		if String(dragons[index].get("definition_id", "")) == "voltara":
			dragons.remove_at(index)
			removed_voltara = true
	if not removed_voltara:
		return false
	for egg: Dictionary in eggs:
		if String(egg.get("definition_id", "")) == "voltara":
			return true
	_append_egg(&"voltara", FUSION_EGG_REQUIRED_STEPS)
	return true


func _dragon_type_key(dragon: Dictionary) -> String:
	return _definition_type_key(StringName(String(dragon.get("definition_id", ""))))


func _definition_type_key(definition_id: StringName) -> String:
	var definition := catalog.get_dragon(definition_id)
	if definition == null or definition.types.is_empty():
		return String(definition_id)
	var type_names := PackedStringArray()
	for type_id: StringName in definition.types:
		type_names.append(String(type_id))
	type_names.sort()
	return "|".join(type_names)


func _merge_duplicate_dragons(existing: Dictionary, candidate: Dictionary) -> Dictionary:
	var keep := existing.duplicate(true)
	var other := candidate
	if bool(candidate.get("starter", false)) and not bool(existing.get("starter", false)):
		keep = candidate.duplicate(true)
		other = existing
	keep["hunger"] = maxi(int(keep.get("hunger", 0)), int(other.get("hunger", 0)))
	keep["cleanliness"] = maxf(
		float(keep.get("cleanliness", 0.0)),
		float(other.get("cleanliness", 0.0))
	)
	keep["care_points"] = maxi(
		int(keep.get("care_points", 0)),
		int(other.get("care_points", 0))
	)
	var merged_training: Dictionary = keep.get("training_xp", {}).duplicate(true)
	var other_training: Variant = other.get("training_xp", {})
	if other_training is Dictionary:
		for category: Variant in other_training:
			var key := String(category)
			merged_training[key] = maxi(
				int(merged_training.get(key, 0)),
				int(other_training[category])
			)
	keep["training_xp"] = merged_training
	keep["flight_contest_wins"] = maxi(
		int(keep.get("flight_contest_wins", 0)),
		int(other.get("flight_contest_wins", 0))
	)
	return keep


func _normalize_dragon(dragon: Dictionary, legacy_care: Dictionary) -> Dictionary:
	var definition_id := catalog.resolve_legacy_dragon(dragon)
	if not catalog.has_dragon(definition_id):
		return {}
	var training_xp: Dictionary = {}
	var saved_training: Variant = dragon.get("training_xp", {})
	if saved_training is Dictionary:
		for category: Variant in saved_training:
			training_xp[String(category)] = maxi(0, int(saved_training[category]))
	if not training_xp.has(String(FLIGHT_CATEGORY)):
		training_xp[String(FLIGHT_CATEGORY)] = maxi(0, int(dragon.get("flight_xp", 0)))
	var instance_id := String(dragon.get("id", ""))
	if instance_id.is_empty():
		instance_id = "dragon-%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	return {
		"id": instance_id,
		"definition_id": String(definition_id),
		"starter": bool(dragon.get("starter", false)),
		"hunger": clampi(int(dragon.get("hunger", legacy_care["hunger"])), 0, 100),
		"cleanliness": clampf(float(dragon.get("cleanliness", legacy_care["cleanliness"])), 0.0, 100.0),
		"care_points": maxi(0, int(dragon.get("care_points", legacy_care["care_points"]))),
		"training_xp": training_xp,
		"flight_contest_wins": clampi(
			int(dragon.get("flight_contest_wins", 0)),
			0,
			FLIGHT_CONTEST_GOALS.size()
		),
	}


func _normalize_egg(egg: Dictionary) -> Dictionary:
	var definition_id := catalog.resolve_legacy_egg(egg)
	if not catalog.has_dragon(definition_id):
		return {}
	var egg_id := String(egg.get("id", ""))
	if egg_id.is_empty():
		egg_id = "egg-%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	return {
		"id": egg_id,
		"definition_id": String(definition_id),
		"required_steps": maxi(1, int(egg.get("required_steps", EGG_REQUIRED_STEPS))),
		"progress_steps": maxi(0, int(egg.get("progress_steps", 0))),
		"incubation_start": maxi(0, int(egg.get("incubation_start", 0))),
		"mock_baseline": maxi(0, int(egg.get("mock_baseline", 0))),
	}


func get_dragon(dragon_id: String) -> Dictionary:
	for dragon: Dictionary in dragons:
		if String(dragon.get("id", "")) == dragon_id:
			return dragon
	return {}


func _dragon_index(dragon_id: String) -> int:
	for index in dragons.size():
		if String(dragons[index].get("id", "")) == dragon_id:
			return index
	return -1


func dragon_definition(dragon: Dictionary) -> DragonDefinition:
	return catalog.get_dragon(StringName(String(dragon.get("definition_id", ""))))


func dragon_name_key(dragon: Dictionary) -> String:
	var definition := dragon_definition(dragon)
	return String(definition.name_key) if definition != null else "DRAGON_NAME"


func dragon_level_species_key(dragon: Dictionary) -> String:
	var definition := dragon_definition(dragon)
	if definition == null or definition.level_species_key.is_empty():
		return "LEVEL_SPECIES"
	return String(definition.level_species_key)


func dragon_has_type(dragon: Dictionary, type_id: StringName) -> bool:
	var definition := dragon_definition(dragon)
	return definition != null and definition.has_type(type_id)


func dragon_texture(dragon: Dictionary) -> Texture2D:
	var definition := dragon_definition(dragon)
	return _load_texture(definition.dragon_texture_path if definition != null else "")


func island_texture(dragon: Dictionary) -> Texture2D:
	var definition := dragon_definition(dragon)
	return _load_texture(definition.island_texture_path if definition != null else "")


func flight_texture(dragon: Dictionary) -> Texture2D:
	var definition := dragon_definition(dragon)
	return _load_texture(definition.flight_texture_path if definition != null else "")


func get_dragon_hunger(dragon_id: String) -> int:
	return clampi(int(get_dragon(dragon_id).get("hunger", DEFAULT_HUNGER)), 0, 100)


func set_dragon_hunger(dragon_id: String, value: int, commit := false) -> void:
	var index := _dragon_index(dragon_id)
	if index < 0:
		return
	dragons[index]["hunger"] = clampi(value, 0, 100)
	if commit:
		_commit_change()


func get_dragon_cleanliness(dragon_id: String) -> float:
	return clampf(float(get_dragon(dragon_id).get("cleanliness", DEFAULT_CLEANLINESS)), 0.0, 100.0)


func set_dragon_cleanliness(dragon_id: String, value: float, commit := false) -> void:
	var index := _dragon_index(dragon_id)
	if index < 0:
		return
	dragons[index]["cleanliness"] = clampf(value, 0.0, 100.0)
	if commit:
		_commit_change()


func get_dragon_care_points(dragon_id: String) -> int:
	return maxi(0, int(get_dragon(dragon_id).get("care_points", 0)))


func set_dragon_care_points(dragon_id: String, value: int, commit := false) -> void:
	var index := _dragon_index(dragon_id)
	if index < 0:
		return
	dragons[index]["care_points"] = maxi(0, value)
	if commit:
		_commit_change()


func get_dragon_happiness(dragon_id: String) -> int:
	return CareRules.happiness(get_dragon(dragon_id))


func get_training_xp(dragon_id: String, category_id: StringName) -> int:
	var training: Variant = get_dragon(dragon_id).get("training_xp", {})
	if not training is Dictionary:
		return 0
	return maxi(0, int(training.get(String(category_id), 0)))


func get_training_level(dragon_id: String, category_id: StringName) -> int:
	var category := catalog.get_training_category(category_id)
	if category == null:
		return 0
	return category.level_for_xp(get_training_xp(dragon_id, category_id))


func add_training_xp(dragon_id: String, category_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	var index := _dragon_index(dragon_id)
	if index < 0 or catalog.get_training_category(category_id) == null:
		return
	var dragon := dragons[index]
	var training: Dictionary = dragon.get("training_xp", {}).duplicate(true)
	var key := String(category_id)
	training[key] = maxi(0, int(training.get(key, 0))) + amount
	dragon["training_xp"] = training
	dragons[index] = dragon
	_commit_change()


func can_enter_training_contest(dragon_id: String, category_id: StringName) -> bool:
	var category := catalog.get_training_category(category_id)
	return category != null and get_training_level(dragon_id, category_id) >= category.contest_level


func training_contest_value(dragon_id: String, category_id: StringName) -> int:
	var category := catalog.get_training_category(category_id)
	if category == null:
		return 0
	return category.contest_value_for_xp(get_training_xp(dragon_id, category_id))


func complete_training_contest(dragon_id: String, category_id: StringName) -> int:
	var category := catalog.get_training_category(category_id)
	if category == null or not can_enter_training_contest(dragon_id, category_id):
		return 0
	gold += maxi(0, category.gold_reward)
	_commit_change()
	return maxi(0, category.gold_reward)


func get_flight_xp(dragon_id: String) -> int:
	return get_training_xp(dragon_id, FLIGHT_CATEGORY)


func get_flight_level(dragon_id: String) -> int:
	return get_training_level(dragon_id, FLIGHT_CATEGORY)


func add_flight_xp(dragon_id: String, amount: int) -> void:
	add_training_xp(dragon_id, FLIGHT_CATEGORY, amount)


func can_enter_flight_contest(dragon_id: String) -> bool:
	var goal := flight_contest_goal(dragon_id)
	return goal > 0 and flight_contest_distance(dragon_id) >= goal


func flight_contest_distance(dragon_id: String) -> int:
	return training_contest_value(dragon_id, FLIGHT_CATEGORY)


func flight_contest_wins(dragon_id: String) -> int:
	return clampi(
		int(get_dragon(dragon_id).get("flight_contest_wins", 0)),
		0,
		FLIGHT_CONTEST_GOALS.size()
	)


func flight_contest_goal(dragon_id: String) -> int:
	var wins := flight_contest_wins(dragon_id)
	if wins >= FLIGHT_CONTEST_GOALS.size():
		return 0
	return FLIGHT_CONTEST_GOALS[wins]


func flight_contest_required_level(dragon_id: String) -> int:
	var goal := flight_contest_goal(dragon_id)
	return ceili(float(goal) / float(FLIGHT_METERS_PER_LEVEL)) if goal > 0 else 0


func flight_contest_opponent_distances(dragon_id: String) -> Array[int]:
	match flight_contest_wins(dragon_id):
		0:
			return [38, 44, 48]
		1:
			return [56, 63, 68]
		_:
			return [82, 91, 98]


func complete_flight_contest(dragon_id: String, distance: int = -1) -> int:
	var index := _dragon_index(dragon_id)
	if index < 0 or not can_enter_flight_contest(dragon_id):
		return 0
	var flown_distance := flight_contest_distance(dragon_id) if distance < 0 else distance
	var opponents := flight_contest_opponent_distances(dragon_id)
	var opponent_best := 0
	for opponent_distance: int in opponents:
		opponent_best = maxi(opponent_best, opponent_distance)
	if flown_distance <= opponent_best:
		return 0
	var dragon := dragons[index]
	dragon["flight_contest_wins"] = flight_contest_wins(dragon_id) + 1
	dragons[index] = dragon
	var category := catalog.get_training_category(FLIGHT_CATEGORY)
	var reward := maxi(0, category.gold_reward) if category != null else 0
	gold += reward
	_commit_change()
	return reward


func can_purchase_egg(kind: String) -> bool:
	var egg_kind_id := StringName(kind)
	if gold < EGG_PRICE_GOLD or eggs.size() + dragons.size() >= DRAGON_CAPACITY:
		return false
	return is_shop_egg_available(kind)


func is_shop_egg_available(kind: String) -> bool:
	var egg_kind_id := StringName(kind)
	if not SHOP_EGG_KINDS.has(egg_kind_id):
		return false
	var definition_id := collection.next_unowned_egg(egg_kind_id, dragons, eggs)
	return not definition_id.is_empty() and not owns_dragon_type(definition_id)


func owns_dragon_type(definition_id: StringName) -> bool:
	var requested_type_key := _definition_type_key(definition_id)
	for dragon: Dictionary in dragons:
		if _dragon_type_key(dragon) == requested_type_key:
			return true
	return false


func purchase_egg(kind: String = "fire") -> String:
	if not can_purchase_egg(kind):
		return ""
	var definition_id := collection.next_unowned_egg(StringName(kind), dragons, eggs)
	gold -= EGG_PRICE_GOLD
	var egg_id := _append_egg(definition_id)
	_commit_change()
	return egg_id


func _append_egg(
	definition_id: StringName,
	required_steps := EGG_REQUIRED_STEPS
) -> String:
	var egg_id := "egg-%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	eggs.append({
		"id": egg_id,
		"definition_id": String(definition_id),
		"required_steps": maxi(1, required_steps),
		"progress_steps": 0,
		"incubation_start": 0,
		"mock_baseline": 0,
	})
	return egg_id


func get_egg(egg_id: String) -> Dictionary:
	for egg: Dictionary in eggs:
		if String(egg.get("id", "")) == egg_id:
			return egg
	return {}


func egg_definition(egg: Dictionary) -> DragonDefinition:
	return catalog.get_dragon(StringName(String(egg.get("definition_id", ""))))


func egg_kind(egg: Dictionary) -> String:
	var definition := egg_definition(egg)
	return String(definition.egg_kind) if definition != null else "sunwing"


func egg_name_key(egg: Dictionary) -> String:
	var definition := egg_definition(egg)
	if definition == null:
		return "EGG_NAME"
	if not definition.egg_name_key.is_empty():
		return String(definition.egg_name_key)
	return "EGG_NAME"


func egg_hatch_message_key(egg: Dictionary) -> String:
	var definition := egg_definition(egg)
	if definition == null or definition.hatch_message_key.is_empty():
		return "HATCHED_MESSAGE"
	return String(definition.hatch_message_key)


func egg_texture(egg: Dictionary) -> Texture2D:
	var definition := egg_definition(egg)
	return _load_texture(definition.egg_texture_path if definition != null else "")


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(path) as Texture2D


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
		var definition_id := StringName(String(eggs[index].get("definition_id", "")))
		if owns_dragon_type(definition_id):
			return false
		eggs.remove_at(index)
		dragons.append(_new_dragon(definition_id))
		_commit_change()
		return true
	return false


func unlock_dragon(
	definition_id: StringName,
	instance_id := "",
	starter := false,
	commit := true
) -> String:
	if not catalog.has_dragon(definition_id):
		return ""
	if dragons.size() >= DRAGON_CAPACITY or owns_dragon_type(definition_id):
		return ""
	var dragon := _new_dragon(definition_id, instance_id, starter)
	dragons.append(dragon)
	if commit:
		_commit_change()
	return String(dragon["id"])


func can_fuse(first_id: String, second_id: String) -> bool:
	return fusion_eligibility_error(first_id, second_id).is_empty()


func fusion_eligibility_error(first_id: String, second_id: String) -> StringName:
	var first := get_dragon(first_id)
	var second := get_dragon(second_id)
	var error := fusion.eligibility_error(
		first,
		second,
		dragons,
		fusion_stars
	)
	if error in [&"missing_parent", &"same_parent", &"no_recipe", &"already_owned"]:
		return error
	var result_definition := fusion.result_for(first, second)
	for egg: Dictionary in eggs:
		if StringName(String(egg.get("definition_id", ""))) == result_definition:
			return &"fusion_pending"
	if not error.is_empty():
		return error
	if dragons.size() + eggs.size() >= DRAGON_CAPACITY:
		return &"den_full"
	return StringName()


func fusion_result_for(first_id: String, second_id: String) -> StringName:
	return fusion.result_for(get_dragon(first_id), get_dragon(second_id))


func fuse_dragons(first_id: String, second_id: String) -> String:
	var first := get_dragon(first_id)
	var second := get_dragon(second_id)
	if not can_fuse(first_id, second_id):
		return ""
	var first_definition := StringName(String(first.get("definition_id", "")))
	var second_definition := StringName(String(second.get("definition_id", "")))
	var recipe := catalog.get_fusion_recipe(first_definition, second_definition)
	if recipe == null:
		return ""
	var result_id := _append_egg(recipe.result, FUSION_EGG_REQUIRED_STEPS)
	fusion_stars -= recipe.fusion_star_cost
	_commit_change()
	return result_id


func _commit_change() -> void:
	if persistence_enabled:
		save_game()
	state_changed.emit()


func reset_app() -> void:
	_reset_defaults()
	if persistence_enabled and FileAccess.file_exists(SAVE_PATH):
		var save_path := ProjectSettings.globalize_path(SAVE_PATH)
		var error := DirAccess.remove_absolute(save_path)
		if error != OK:
			push_error("Could not remove saved game during app reset.")
	state_changed.emit()


func reset_for_tests() -> void:
	persistence_enabled = false
	_reset_defaults()
	state_changed.emit()
