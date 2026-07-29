extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var step_counter := root.get_node("StepCounter")
	game_state.reset_for_tests()

	var packed_scene: PackedScene = load("res://main.tscn")
	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame

	scene.call("_show_den")
	assert(scene.get("current_screen") == "den")
	game_state.gold = 1
	scene.call("_show_shop")
	scene.call("_purchase_egg")
	assert(game_state.eggs.size() == 1, "One gold coin must purchase an egg.")
	assert(game_state.eggs[0].get("kind") == "ice", "The shop egg must be the ice dragon's frost crystal egg.")
	assert(game_state.gold == 0, "Purchasing an egg must consume one gold coin.")
	assert(scene.get("current_screen") == "egg_detail")

	scene.call("_start_current_egg")
	for _stroke in 4:
		step_counter.add_mock_steps(250)
		scene.call("_refresh_current_egg_steps")
		await process_frame
		await process_frame
	var egg_id: String = scene.get("current_egg_id")
	assert(game_state.can_hatch(egg_id), "1,000 mock steps must make the egg hatchable.")
	scene.call("_hatch_current_egg")
	assert(game_state.dragons.size() == 2, "Hatching must add a dragon.")
	assert(game_state.eggs.is_empty(), "Hatching must consume the egg.")
	var ice_dragon: Dictionary = game_state.dragons[1]
	assert(ice_dragon.get("species") == "ice", "The frost crystal egg must hatch an ice dragon.")
	assert(ice_dragon.get("name_key") == "ICE_DRAGON_NAME", "The ice hatchling must use its species name.")
	await create_timer(1.7).timeout
	assert(scene.get("current_screen") == "dragons")
	var ice_dragon_id := String(ice_dragon.get("id"))
	scene.call("_select_dragon", ice_dragon_id)
	assert(scene.get("current_screen") == "habitat")
	assert(
		String(scene.get("active_dragon_texture").resource_path).ends_with("ice_dragon_hd.png"),
		"The ice dragon must use its own habitat sprite."
	)

	scene.call("_show_grooming")
	scene.call("debug_groom_stroke")
	assert(scene.get("cleanliness") == 100.0)
	await create_timer(1.7).timeout
	assert(scene.get("current_screen") == "habitat")

	scene.call("_show_competition")
	assert(scene.get("current_screen") == "flight_hub")
	var flight_game_script: GDScript = load("res://scripts/ui/flight_game.gd")
	var minigame: Control = flight_game_script.new()
	minigame.size = Vector2(720, 1100)
	root.add_child(minigame)
	await process_frame
	minigame.call("_spawn_obstacle_pair")
	assert(minigame.get("obstacles").size() == 1, "Flight Training must spawn a top/bottom rock-spike pair.")
	assert(minigame.get("dragon").flip_h, "The training dragon must face the direction of travel.")
	minigame.set("score", 9)
	var obstacle_root: Control = minigame.get("obstacles")[0]["root"]
	obstacle_root.position.x = -20
	minigame.call("_move_obstacles", 0.0)
	assert(minigame.get("score") == 10, "Clearing the tenth obstacle must still award XP.")
	assert(not minigame.get("finished"), "Flight Training must continue beyond ten obstacles.")
	minigame.queue_free()
	scene.call("_show_flight_training")
	for score in 50:
		scene.call("_on_flight_score_changed", score + 1)
	assert(game_state.get_flight_level(ice_dragon_id) == 5, "Fifty obstacles in one run must reach Flight Level 5.")
	assert(game_state.can_enter_flight_contest(ice_dragon_id), "Flight Contest must unlock at Level 5.")
	scene.call("_show_flight_contest")
	assert(scene.get("current_screen") == "flight_contest")
	scene.call("_complete_flight_contest", 50)
	assert(game_state.gold == 1, "A 50 m flight contest must award one gold coin.")

	print("Gameplay smoke test: valid")
	quit()
