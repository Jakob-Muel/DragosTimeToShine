class_name TrainingService
extends RefCounted

## Pure talent-progression rules. This service never saves and never touches UI nodes.

const MAX_APPLIED_RUNS := 32


func evaluate_result(
	dragon: Dictionary,
	definition: TrainingCategoryDefinition,
	result: Dictionary,
	xp_multiplier := 1.0
) -> Dictionary:
	if dragon.is_empty() or definition == null:
		return _rejected()
	var talent_id := String(result.get("talent_id", ""))
	var run_id := String(result.get("run_id", ""))
	if talent_id != String(definition.id) or run_id.is_empty():
		return _rejected()
	var result_dragon_id := String(result.get("dragon_id", ""))
	if not result_dragon_id.is_empty() and result_dragon_id != String(dragon.get("id", "")):
		return _rejected()

	var applied_runs := _normalized_run_history(dragon.get("applied_training_runs", []))
	if applied_runs.has(run_id):
		return {
			"accepted": false,
			"duplicate": true,
			"talent_id": talent_id,
			"run_id": run_id,
		}

	var updated := dragon.duplicate(true)
	var raw_score := maxi(0, int(result.get("raw_score", 0)))
	var training_xp := _normalized_number_map(updated.get("training_xp", {}))
	var training_records := _normalized_number_map(updated.get("training_records", {}))
	var previous_xp := maxi(0, int(training_xp.get(talent_id, 0)))
	var previous_best := maxi(0, int(training_records.get(talent_id, 0)))
	var bounded_multiplier := clampf(
		xp_multiplier, 1.0, 1.0 + clampf(definition.maximum_care_bonus, 0.0, 1.0)
	)
	var earned_xp := definition.xp_for_score(raw_score, bounded_multiplier)
	var best_score := maxi(previous_best, raw_score)
	training_xp[talent_id] = previous_xp + earned_xp
	training_records[talent_id] = best_score
	applied_runs.append(run_id)
	while applied_runs.size() > MAX_APPLIED_RUNS:
		applied_runs.pop_front()
	updated["training_xp"] = training_xp
	updated["training_records"] = training_records
	updated["applied_training_runs"] = applied_runs

	return {
		"accepted": true,
		"duplicate": false,
		"dragon": updated,
		"talent_id": talent_id,
		"run_id": run_id,
		"raw_score": raw_score,
		"xp_earned": earned_xp,
		"previous_level": definition.level_for_xp(previous_xp),
		"level": definition.level_for_xp(previous_xp + earned_xp),
		"best_score": best_score,
		"new_record": raw_score > previous_best,
		"stars": definition.stars_for_score(best_score),
	}


func _normalized_number_map(value: Variant) -> Dictionary:
	var normalized := {}
	if value is Dictionary:
		for key: Variant in value:
			normalized[String(key)] = maxi(0, int(value[key]))
	return normalized


func _normalized_run_history(value: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if value is Array:
		for entry: Variant in value:
			var run_id := String(entry)
			if not run_id.is_empty() and not normalized.has(run_id):
				normalized.append(run_id)
	while normalized.size() > MAX_APPLIED_RUNS:
		normalized.pop_front()
	return normalized


func _rejected() -> Dictionary:
	return {"accepted": false, "duplicate": false}
