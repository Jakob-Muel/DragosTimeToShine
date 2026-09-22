extends Node

signal state_changed

const ATTRIBUTES := preload("res://scripts/domain/dragon_attributes.gd")

const SAVE_PATH := "user://dragos_save.json"
const SAVE_SCHEMA_VERSION := 11
const DRAGON_CAPACITY := 12
const EGG_REQUIRED_STEPS := 5000
const FUSION_EGG_REQUIRED_STEPS := 5000
const EGG_PRICE_GOLD := 1
const SHOP_EGG_KINDS: Array[StringName] = [&"random"]
const RANDOM_DRAGON_POOL: Array[StringName] = [&"luma", &"frost", &"ember", &"marina", &"terra"]
const FLIGHT_CATEGORY := &"flight"
const ELEMENT_POWER_CATEGORY := &"element_power"
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
var training := TrainingService.new()


func _ready() -> void:
	# Test/script runners must never migrate or overwrite the player's real save.
	var args := OS.get_cmdline_args()
	if args.has("--script") or args.has("-s"):
		persistence_enabled = false
	_reset_defaults()
	if persistence_enabled:
		load_game()


func _reset_defaults() -> void:
	gems = 125
	gold = 0
	fusion_stars = DEFAULT_FUSION_STARS
	dragons = []
	eggs = [{
		"id": "starter-egg", "definition_id": String(RANDOM_DRAGON_POOL.pick_random()), "starter": true,
		"appearance_seed": randi_range(1, 2147483646),
		"required_steps": 1, "progress_steps": 1,
		"incubation_start": 0, "mock_baseline": 0,
	}]
	eggs[0] = _normalize_egg(eggs[0])


func starter_egg_id() -> String:
	for egg: Dictionary in eggs:
		if bool(egg.get("starter", false)):
			return String(egg["id"])
	return ""


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
	var appearance_seed := randi_range(1, 2147483646)
	return {
		"id": instance_id,
		"definition_id": String(definition_id),
		"starter": starter,
		"appearance_seed": appearance_seed,
		"attributes": ATTRIBUTES.normalize({}, appearance_seed, true),
		"genetics_version": ATTRIBUTES.VERSION,
		"parent_ids": [],
		"inheritance": {},
		"generation": 0,
		"hunger": clampi(hunger, 0, 100),
		"cleanliness": clampf(cleanliness, 0.0, 100.0),
		"care_points": maxi(0, care_points),
		"training_xp": {
			String(FLIGHT_CATEGORY): 0,
			String(ELEMENT_POWER_CATEGORY): 0,
		},
		"training_records": {
			String(FLIGHT_CATEGORY): 0,
			String(ELEMENT_POWER_CATEGORY): 0,
		},
		"applied_training_runs": [],
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
	if saved_dragons is Array:
		for value: Variant in saved_dragons:
			if value is Dictionary:
				var normalized := _normalize_dragon(value, legacy_care)
				if normalized.is_empty():
					continue
				normalized_dragons.append(normalized)
	dragons = normalized_dragons

	var saved_eggs: Variant = payload.get("eggs", [])
	var normalized_eggs: Array[Dictionary] = []
	if saved_eggs is Array:
		for value: Variant in saved_eggs:
			if value is Dictionary:
				var normalized := _normalize_egg(value)
				if version < 9 and not bool(normalized.get("starter", false)) and int(normalized.get("required_steps", 0)) == 1000:
					normalized["required_steps"] = EGG_REQUIRED_STEPS
				if normalized.is_empty():
					continue
				normalized_eggs.append(normalized)
	eggs = normalized_eggs
	if dragons.is_empty() and eggs.is_empty():
		_reset_defaults()
	if version < 4 and _migrate_direct_voltara_to_fusion_egg():
		should_resave = true
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
	var merged_records: Dictionary = keep.get("training_records", {}).duplicate(true)
	var other_records: Variant = other.get("training_records", {})
	if other_records is Dictionary:
		for category: Variant in other_records:
			var key := String(category)
			merged_records[key] = maxi(
				int(merged_records.get(key, 0)),
				int(other_records[category])
			)
	keep["training_records"] = merged_records
	var merged_runs: Array = keep.get("applied_training_runs", []).duplicate()
	var other_runs: Variant = other.get("applied_training_runs", [])
	if other_runs is Array:
		for value: Variant in other_runs:
			var run_id := String(value)
			if not run_id.is_empty() and not merged_runs.has(run_id):
				merged_runs.append(run_id)
	while merged_runs.size() > TrainingService.MAX_APPLIED_RUNS:
		merged_runs.pop_front()
	keep["applied_training_runs"] = merged_runs
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
	for category_id: StringName in catalog.training_category_ids():
		if not training_xp.has(String(category_id)):
			training_xp[String(category_id)] = 0
	var training_records := _normalize_training_number_map(dragon.get("training_records", {}))
	for category_id: StringName in catalog.training_category_ids():
		if not training_records.has(String(category_id)):
			training_records[String(category_id)] = 0
	var applied_training_runs := _normalize_training_run_history(
		dragon.get("applied_training_runs", [])
	)
	var instance_id := String(dragon.get("id", ""))
	if instance_id.is_empty():
		instance_id = "dragon-%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	return {
		"id": instance_id,
		"definition_id": String(definition_id),
		"starter": bool(dragon.get("starter", false)),
		"appearance_seed": ProceduralDragonTextures.seed_for(dragon),
		"attributes": ATTRIBUTES.normalize(dragon.get("attributes", {}), ProceduralDragonTextures.seed_for(dragon)),
		"genetics_version": int(dragon.get("genetics_version", ATTRIBUTES.VERSION)),
		"parent_ids": dragon.get("parent_ids", []).duplicate(),
		"inheritance": dragon.get("inheritance", {}).duplicate(),
		"generation": maxi(0, int(dragon.get("generation", 0))),
		"hunger": clampi(int(dragon.get("hunger", legacy_care["hunger"])), 0, 100),
		"cleanliness": clampf(float(dragon.get("cleanliness", legacy_care["cleanliness"])), 0.0, 100.0),
		"care_points": maxi(0, int(dragon.get("care_points", legacy_care["care_points"]))),
		"training_xp": training_xp,
		"training_records": training_records,
		"applied_training_runs": applied_training_runs,
		"flight_contest_wins": clampi(
			int(dragon.get("flight_contest_wins", 0)),
			0,
			FLIGHT_CONTEST_GOALS.size()
		),
	}


func _normalize_training_number_map(value: Variant) -> Dictionary:
	var normalized := {}
	if value is Dictionary:
		for category: Variant in value:
			normalized[String(category)] = maxi(0, int(value[category]))
	return normalized


func _normalize_training_run_history(value: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if value is Array:
		for entry: Variant in value:
			var run_id := String(entry)
			if not run_id.is_empty() and not normalized.has(run_id):
				normalized.append(run_id)
	while normalized.size() > TrainingService.MAX_APPLIED_RUNS:
		normalized.pop_front()
	return normalized


func _normalize_egg(egg: Dictionary) -> Dictionary:
	var definition_id := catalog.resolve_legacy_egg(egg)
	if not catalog.has_dragon(definition_id):
		return {}
	var egg_id := String(egg.get("id", ""))
	if egg_id.is_empty():
		egg_id = "egg-%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	var seed_value := int(egg.get("appearance_seed", randi_range(1, 2147483646)))
	return {
		"id": egg_id,
		"definition_id": String(definition_id),
		"starter": bool(egg.get("starter", false)),
		"attributes": ATTRIBUTES.normalize(egg.get("attributes", {}), seed_value, true),
		"genetics_version": int(egg.get("genetics_version", ATTRIBUTES.VERSION)),
		"parent_ids": egg.get("parent_ids", []).duplicate(),
		"inheritance": egg.get("inheritance", {}).duplicate(),
		"generation": maxi(0, int(egg.get("generation", 0))),
		"appearance_seed": seed_value,
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
	return ProceduralDragonTextures.texture_for(ProceduralDragonTextures.seed_for(dragon), "portrait")


func island_texture(_dragon: Dictionary) -> Texture2D:
	return load("res://assets/art/comic/universal_island.png") as Texture2D


func flight_texture(dragon: Dictionary) -> Texture2D:
	return ProceduralDragonTextures.texture_for(ProceduralDragonTextures.seed_for(dragon), "flight")


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


func get_training_best_score(dragon_id: String, category_id: StringName) -> int:
	var records: Variant = get_dragon(dragon_id).get("training_records", {})
	if not records is Dictionary:
		return 0
	return maxi(0, int(records.get(String(category_id), 0)))


func get_training_stars(dragon_id: String, category_id: StringName) -> int:
	var category := catalog.get_training_category(category_id)
	if category == null:
		return 1
	return category.stars_for_score(get_training_best_score(dragon_id, category_id))


func training_category_ids() -> Array[StringName]:
	return catalog.training_category_ids()


func create_training_session(dragon_id: String, category_id: StringName) -> Dictionary:
	if get_dragon(dragon_id).is_empty() or catalog.get_training_category(category_id) == null:
		return {}
	return {
		"run_id": "run-%s-%d-%d" % [
			String(category_id),
			Time.get_ticks_usec(),
			randi_range(1000, 9999),
		],
		"dragon_id": dragon_id,
		"talent_id": String(category_id),
	}


func apply_training_result(dragon_id: String, result: Dictionary, attribute_id: String = "") -> Dictionary:
	var index := _dragon_index(dragon_id)
	if index < 0:
		return {"accepted": false, "duplicate": false}
	var category_id := StringName(String(result.get("talent_id", "")))
	var category := catalog.get_training_category(category_id)
	if category == null:
		return {"accepted": false, "duplicate": false}
	if attribute_id.is_empty():
		attribute_id = ATTRIBUTES.training_attribute(category_id)
	if not ATTRIBUTES.IDS.has(attribute_id):
		return {"accepted": false, "duplicate": false}
	if (attribute_id == "movement_speed") != (category_id == FLIGHT_CATEGORY):
		return {"accepted": false, "duplicate": false}
	var multiplier := CareRules.training_xp_multiplier(
		dragons[index],
		category.maximum_care_bonus
	)
	var evaluation := training.evaluate_result(
		dragons[index],
		category,
		result,
		multiplier
	)
	if not bool(evaluation.get("accepted", false)):
		return evaluation
	dragons[index] = evaluation["dragon"]
	evaluation.erase("dragon")
	evaluation["care_multiplier"] = multiplier
	evaluation["attribute_id"] = attribute_id
	evaluation["attribute_gain"] = ATTRIBUTES.train(dragons[index], attribute_id, int(evaluation.get("xp_earned", 0)))
	_commit_change()
	return evaluation


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


func can_purchase_egg(kind: String = "random") -> bool:
	if gold < EGG_PRICE_GOLD or eggs.size() + dragons.size() >= DRAGON_CAPACITY:
		return false
	return is_shop_egg_available(kind)


func random_egg_candidates() -> Array[StringName]:
	return RANDOM_DRAGON_POOL.duplicate()


func is_shop_egg_available(kind: String = "random") -> bool:
	return kind == "random" and not random_egg_candidates().is_empty()


func owns_dragon_type(definition_id: StringName) -> bool:
	var requested_type_key := _definition_type_key(definition_id)
	for dragon: Dictionary in dragons:
		if _dragon_type_key(dragon) == requested_type_key:
			return true
	return false


func purchase_egg(kind: String = "random") -> String:
	if not can_purchase_egg(kind):
		return ""
	var definition_id: StringName = random_egg_candidates().pick_random()
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
		"starter": false,
		"appearance_seed": randi_range(1, 2147483646),
		"required_steps": maxi(1, required_steps),
		"progress_steps": 0,
		"incubation_start": 0,
		"mock_baseline": 0,
	})
	eggs[eggs.size() - 1] = _normalize_egg(eggs.back())
	return egg_id


func get_egg(egg_id: String) -> Dictionary:
	for egg: Dictionary in eggs:
		if String(egg.get("id", "")) == egg_id:
			return egg
	return {}


func egg_definition(egg: Dictionary) -> DragonDefinition:
	return catalog.get_dragon(StringName(String(egg.get("definition_id", ""))))


func egg_kind(_egg: Dictionary) -> String:
	return "random"


func egg_name_key(_egg: Dictionary) -> String:
	return "RANDOM_EGG_NAME"


func egg_hatch_message_key(egg: Dictionary) -> String:
	var definition := egg_definition(egg)
	if definition == null or definition.hatch_message_key.is_empty():
		return "RANDOM_HATCHED_MESSAGE"
	return String(definition.hatch_message_key)


func egg_texture(_egg: Dictionary) -> Texture2D:
	return preload("res://assets/art/comic/sun_egg.png")


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
		var appearance_seed := int(eggs[index].get("appearance_seed", randi_range(1, 2147483646)))
		var starter := bool(eggs[index].get("starter", false))
		var inherited_egg := eggs[index].duplicate(true)
		eggs.remove_at(index)
		dragons.append(_new_dragon(definition_id, "luma" if starter else "", starter, DEFAULT_HUNGER, DEFAULT_CLEANLINESS, DEFAULT_CARE_POINTS if starter else 0))
		dragons.back()["appearance_seed"] = appearance_seed
		dragons.back()["attributes"] = ATTRIBUTES.normalize(inherited_egg.get("attributes", {}), appearance_seed, true)
		dragons.back()["parent_ids"] = inherited_egg.get("parent_ids", []).duplicate()
		dragons.back()["inheritance"] = inherited_egg.get("inheritance", {}).duplicate()
		dragons.back()["generation"] = int(inherited_egg.get("generation", 0))
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
	if dragons.size() >= DRAGON_CAPACITY:
		return ""
	var dragon := _new_dragon(definition_id, instance_id, starter)
	dragons.append(dragon)
	if commit:
		_commit_change()
	return String(dragon["id"])


func can_fuse(first_id: String, second_id: String) -> bool:
	return fusion_eligibility_error(first_id, second_id).is_empty()


func fusion_eligibility_error(first_id: String, second_id: String) -> StringName:
	var error := fusion.eligibility_error(get_dragon(first_id), get_dragon(second_id), dragons, fusion_stars)
	if not error.is_empty():
		return error
	if dragons.size() + eggs.size() >= DRAGON_CAPACITY:
		return &"den_full"
	return StringName()


func fusion_result_for(first_id: String, second_id: String) -> StringName:
	return fusion.result_for(get_dragon(first_id), get_dragon(second_id))


func fuse_dragons(first_id: String, second_id: String, inheritance: Dictionary = {}) -> String:
	if not can_fuse(first_id, second_id):
		return ""
	var first := get_dragon(first_id)
	var second := get_dragon(second_id)
	var inherited := {}
	var sources := {}
	for attribute: String in ATTRIBUTES.IDS:
		var parent_id := String(inheritance.get(attribute, first_id))
		if parent_id != first_id and parent_id != second_id:
			return ""
		var parent := first if parent_id == first_id else second
		inherited[attribute] = {"value": ATTRIBUTES.BASE_VALUE, "potential": parent["attributes"][attribute]["potential"]}
		sources[attribute] = parent_id
	var result_id := _append_egg(fusion.result_for(first, second), FUSION_EGG_REQUIRED_STEPS)
	var egg := get_egg(result_id)
	egg["attributes"] = inherited
	egg["inheritance"] = sources
	egg["parent_ids"] = [first_id, second_id]
	egg["generation"] = maxi(int(first.get("generation", 0)), int(second.get("generation", 0))) + 1
	fusion_stars -= fusion.cost_for(first, second)
	_commit_change()
	return result_id


func dragon_attributes(dragon_id: String) -> Dictionary:
	return get_dragon(dragon_id).get("attributes", {}).duplicate(true)


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


func reset_for_tests(hatch_starter := true) -> void:
	persistence_enabled = false
	_reset_defaults()
	if hatch_starter:
		eggs[0]["definition_id"] = "luma" # Stable fixture for existing domain tests.
		hatch_egg(starter_egg_id())
	state_changed.emit()
