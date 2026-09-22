extends SceneTree

var completions: Array[Dictionary] = []
var cancellations := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset_for_tests()
	var service := TrainingService.new()
	var catalog := GameCatalog.new()
	var original: Dictionary = state.get_dragon("luma").duplicate(true)
	for talent_id: StringName in catalog.training_category_ids():
		var definition := catalog.get_training_category(talent_id)
		var result := {"run_id": "fixture", "dragon_id": "luma", "talent_id": String(talent_id), "raw_score": 50}
		var evaluated := service.evaluate_result(original, definition, result)
		assert(evaluated.accepted and evaluated.xp_earned == 50)
		assert(evaluated.level == 5 and evaluated.stars == 5)
		assert(evaluated.new_record and evaluated.best_score == 50)
		assert(original == state.get_dragon("luma"), "Evaluation must not mutate its input.")
		assert(service.evaluate_result(evaluated.dragon, definition, result).duplicate)
		result.run_id = "next-fixture"
		result.raw_score = 5
		var next := service.evaluate_result(evaluated.dragon, definition, result)
		assert(next.xp_earned == 5 and next.best_score == 50 and not next.new_record)
		result.raw_score = 40
		assert(service.evaluate_result(original, definition, result, 0.0).xp_earned == 40,
			"Care must never penalize XP.")
		assert(service.evaluate_result(original, definition, result, 99.0).xp_earned == 50,
			"Care must never exceed the configured positive bonus.")
		result.dragon_id = "different-dragon"
		assert(not service.evaluate_result(original, definition, result).accepted)
		result.dragon_id = "luma"
		result.run_id = ""
		assert(not service.evaluate_result(original, definition, result).accepted)
		result.run_id = "wrong-talent"
		result.talent_id = "unknown"
		assert(not service.evaluate_result(original, definition, result).accepted)

	# Exercise the real minigames through the same result contract and facade.
	for path: String in ["res://scripts/ui/flight_game.gd", "res://scripts/ui/flame_shooter_game.gd"]:
		var talent_id := &"flight" if path.ends_with("/flight_game.gd") else &"element_power"
		var game: TalentMinigame = load(path).new()
		var session: Dictionary = state.create_training_session("luma", talent_id)
		game.configure(session)
		session.dragon_id = "changed-outside-game"
		game.run_completed.connect(func(result: Dictionary) -> void: completions.append(result))
		game.score = 20
		if talent_id == &"flight":
			game.call("_finish", false)
		else:
			game.call("_finish", "fixture")
		game.complete_talent_run(999)
		await process_frame
		assert(completions.size() == 1, "A run must report exactly one completion.")
		var result: Dictionary = completions.pop_back()
		assert(result.dragon_id == "luma" and result.raw_score == 20)
		var applied: Dictionary = state.apply_training_result("luma", result)
		assert(applied.accepted and applied.xp_earned >= 20)
		var saved: Dictionary = state.serialize_state()
		assert(state.apply_training_result("luma", result).duplicate)
		assert(state.serialize_state() == saved, "Duplicate completion must not mutate progress.")
		# JSON round-trip covers the actual persistence representation, without touching player files.
		state.load_payload(JSON.parse_string(JSON.stringify(saved)))
		assert(state.get_training_best_score("luma", talent_id) == 20)
		assert(state.get_training_xp("luma", talent_id) == applied.xp_earned)
		assert(state.apply_training_result("luma", result).duplicate,
			"Reloading must retain the duplicate-result guard.")
		game.free()

	var cancelled := TalentMinigame.new()
	cancelled.configure(state.create_training_session("luma", &"flight"))
	cancelled.run_completed.connect(func(result: Dictionary) -> void: completions.append(result))
	cancelled.run_cancelled.connect(func() -> void: cancellations += 1)
	cancelled.cancel_run()
	cancelled.cancel_run()
	cancelled.complete_talent_run(100)
	await process_frame
	assert(cancellations == 1 and completions.is_empty(), "Cancellation must prevent later rewards.")
	cancelled.configure(state.create_training_session("luma", &"flight"))
	cancelled.complete_talent_run(1)
	await process_frame
	assert(completions.size() == 1, "A new session must reset the completion guard.")
	cancelled.free()

	state.load_payload({
		"schema_version": 6,
		"dragons": [{"id": "luma", "definition_id": "luma", "starter": true,
			"training_xp": {"flight": 27, "future_talent": 83},
			"training_records": {"future_talent": 41}}],
		"eggs": [],
	})
	assert(state.get_training_xp("luma", &"flight") == 27)
	assert(state.get_training_xp("luma", &"element_power") == 0)
	assert(state.get_training_xp("luma", &"future_talent") == 83)
	state.load_payload(JSON.parse_string(JSON.stringify(state.serialize_state())))
	assert(state.get_training_best_score("luma", &"future_talent") == 41,
		"Unknown future talent data must survive loading and saving.")
	print("Training contract test: valid")
	quit()
