extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset_for_tests()
	var app: Control = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	# A third talent proves that scene loading and navigation do not branch on talent IDs.
	var extra := TrainingCategoryDefinition.new()
	extra.id = &"fixture_talent"
	extra.name_key = &"TALENT_FLIGHT_NAME"
	extra.minigame_scene = load("res://scenes/minigames/flight_game.tscn")
	state.catalog.register_training_category(extra)
	for talent: String in ["flight", "element_power", "fixture_talent"]:
		app.call("_on_screen_navigation", "training_session", {
			"talent_id": talent, "dragon_id": "luma", "return_route": "flight_hub",
		})
		var screen: GameScreen = app.get("screen_router").active_screen
		assert(app.get("current_screen") == "training_session")
		var game: TalentMinigame = screen.get("game")
		assert(game != null and game.talent_session.talent_id == talent)
		var initial: Dictionary = state.serialize_state()
		var wrong: Dictionary = game.talent_session.duplicate(true)
		wrong["run_id"] = "another-session"
		wrong["raw_score"] = 500
		screen.call("_on_run_completed", wrong)
		assert(state.serialize_state() == initial, "A result from another run must be rejected.")
		game.complete_talent_run(20)
		await process_frame
		assert(screen.get("result_overlay") != null)
		var earned: int = state.get_training_xp("luma", StringName(talent))
		assert(earned >= 20)
		var duplicate: Dictionary = game.talent_session.duplicate(true)
		duplicate["raw_score"] = 20
		screen.call("_on_run_completed", duplicate)
		assert(state.get_training_xp("luma", StringName(talent)) == earned)
		var previous_run := String(game.talent_session.run_id)
		screen.call("_retry")
		screen = app.get("screen_router").active_screen
		game = screen.get("game")
		assert(game.talent_session.run_id != previous_run)
		assert(game.talent_session.talent_id == talent and game.talent_session.dragon_id == "luma")
		# Completion is deferred: leaving before it arrives must not award progress.
		game.complete_talent_run(100)
		screen.call("_leave")
		await process_frame
		assert(app.get("current_screen") == "flight_hub")
		assert(state.get_training_xp("luma", StringName(talent)) == earned)

	app.call("_on_screen_navigation", "training_session", {"talent_id": "unknown"})
	assert(app.get("screen_router").active_screen.get("game") == null)
	app.get("screen_router").active_screen.call("_leave")
	assert(app.get("current_screen") == "main")
	app.queue_free()
	await process_frame

	var localization := root.get_node("Localization")
	for locale: String in ["de", "en"]:
		localization.set_locale(locale)
		for talent: String in ["flight", "element_power"]:
			var definition: TrainingCategoryDefinition = state.catalog.get_training_category(StringName(talent))
			for key: StringName in [definition.name_key, definition.instruction_key]:
				assert(localization.text(String(key)) != String(key), "Talent metadata must be translated.")
			for height: float in [1280.0, 1565.0]:
				var screen: GameScreen = load("res://scenes/screens/training_session_screen.tscn").instantiate()
				screen.configure({"canvas_size": Vector2(720, height), "safe_top_inset": 122.0,
					"safe_bottom_inset": 64.0, "talent_id": talent, "dragon_id": "luma"})
				root.add_child(screen)
				screen.build()
				var game: TalentMinigame = screen.get("game")
				game.complete_talent_run(50)
				await process_frame
				_check_layout(screen, height)
				screen.queue_free()
				await process_frame
	print("Training session test: valid")
	quit()


func _check_layout(node: Node, height: float) -> void:
	if node is Button:
		var rect: Rect2 = node.get_global_rect()
		assert(rect.position.y >= 122.0 and rect.end.y <= height - 64.0)
	if node is Label:
		assert(not node.text.begins_with("TRAINING_") and not node.text.begins_with("TALENT_"), "All training labels must be translated.")
		assert(node.get_minimum_size().x <= node.size.x + 1, "Training text must fit its label: " + node.text)
	for child in node.get_children():
		_check_layout(child, height)
