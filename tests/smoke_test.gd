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
	assert(game_state.can_purchase_egg("fire"), "The Fire Egg must be selectable for one gold.")
	assert(game_state.can_purchase_egg("water"), "The Water Egg must be selectable for one gold.")
	assert(game_state.can_purchase_egg("earth"), "The Earth Egg must be selectable for one gold.")
	assert(not game_state.can_purchase_egg("ice"), "The Frost Egg must stay outside the active shop.")
	scene.call("_purchase_egg", "fire")
	assert(game_state.eggs.size() == 1, "One gold coin must purchase an egg.")
	assert(
		game_state.eggs[0].get("definition_id") == "ember",
		"The Fire Egg must reserve the unowned Ember dragon."
	)
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
	var fire_dragon: Dictionary = game_state.dragons[1]
	assert(fire_dragon.get("definition_id") == "ember", "The Fire Egg must hatch Ember.")
	assert(game_state.dragon_has_type(fire_dragon, &"fire"), "Ember must have the fire type.")
	assert(game_state.dragon_name_key(fire_dragon) == "FIRE_DRAGON_NAME", "Ember must use its catalog name.")
	await create_timer(1.7).timeout
	assert(scene.get("current_screen") == "dragons")
	var fire_dragon_id := String(fire_dragon.get("id"))
	scene.call("_select_dragon", fire_dragon_id)
	assert(scene.get("current_screen") == "habitat")
	var habitat_screen: Control = scene.get("screen_router").active_screen
	assert(
		String(habitat_screen.get("active_dragon_texture").resource_path).ends_with("fire_dragon_hd.png"),
		"The fire dragon must use its own habitat sprite."
	)
	assert(
		String(habitat_screen.get("active_island_texture").resource_path).ends_with("fire_island_hd.png"),
		"The fire dragon must use its own island."
	)

	scene.call("_show_grooming")
	scene.call("debug_groom_stroke")
	assert(scene.get("cleanliness") == 100.0)
	assert(
		game_state.get_dragon_cleanliness("luma") == game_state.DEFAULT_CLEANLINESS,
		"Grooming Ember must not change Luma's care state."
	)
	await create_timer(1.7).timeout
	assert(scene.get("current_screen") == "habitat")

	scene.call("_show_competition")
	assert(scene.get("current_screen") == "flight_select", "The contest section must start with dragon selection.")
	scene.call("_show_flight_hub")
	assert(scene.get("current_screen") == "flight_hub")
	var flight_game_script: GDScript = load("res://scripts/ui/flight_game.gd")
	var minigame: Control = flight_game_script.new()
	minigame.size = Vector2(720, 1100)
	root.add_child(minigame)
	await process_frame
	minigame.call("_spawn_obstacle_pair")
	assert(minigame.get("obstacles").size() == 1, "Flight Training must spawn a top/bottom rock-spike pair.")
	assert(
		is_equal_approx(float(minigame.get("obstacles")[0].get("gap_height")), 300.0),
		"The first spawned opening must be 300 pixels high."
	)
	assert(minigame.get("dragon").flip_h, "The training dragon must face the direction of travel.")
	for _obstacle_index in 24:
		var previous_gap := float(minigame.get("last_gap_center"))
		minigame.call("_spawn_obstacle_pair")
		var next_gap := float(minigame.get("last_gap_center"))
		assert(
			absf(next_gap - previous_gap) <= 200.01,
			"Early training gaps must stay within the initial 200-pixel delta."
		)
	assert(
		is_equal_approx(float(minigame.call("current_gap_center_delta")), 200.0),
		"Flight gap delta must begin at 200 pixels."
	)
	assert(
		is_equal_approx(float(minigame.call("current_gap_center_min_delta")), 0.0),
		"Early flight gaps must not force a minimum center shift."
	)
	assert(
		is_equal_approx(float(minigame.call("current_gap_height")), 300.0),
		"Flight opening must begin at 300 pixels."
	)
	minigame.set("score", 5)
	assert(
		is_equal_approx(float(minigame.call("current_gap_height")), 285.0),
		"Flight opening must shrink by 15 pixels after five obstacles."
	)
	minigame.set("score", 20)
	assert(
		is_equal_approx(float(minigame.call("current_gap_center_delta")), 500.0),
		"Flight gap delta must grow to at most 500 pixels."
	)
	assert(
		is_equal_approx(float(minigame.call("current_gap_center_min_delta")), 105.0),
		"At 20 obstacles, opening centers must differ by at least 105 pixels."
	)
	minigame.set("last_gap_center", 550.0)
	var before_forced_shift := float(minigame.get("last_gap_center"))
	minigame.call("_spawn_obstacle_pair")
	assert(
		absf(float(minigame.get("last_gap_center")) - before_forced_shift) >= 104.99,
		"Spawned openings must honor the score-tier minimum center shift."
	)
	minigame.set("score", 35)
	assert(
		is_equal_approx(float(minigame.call("current_gap_center_min_delta")), 150.0),
		"Flight minimum center delta must cap at 150 pixels."
	)
	minigame.set("last_gap_center", 550.0)
	before_forced_shift = float(minigame.get("last_gap_center"))
	minigame.call("_spawn_obstacle_pair")
	assert(
		absf(float(minigame.get("last_gap_center")) - before_forced_shift) >= 149.99,
		"Late spawned openings must move by at least 150 pixels."
	)
	minigame.set("score", 60)
	assert(
		is_equal_approx(float(minigame.call("current_gap_height")), 130.0),
		"Flight opening must never shrink below 130 pixels."
	)
	minigame.call("_spawn_obstacle_pair")
	var final_opening: Dictionary = minigame.get("obstacles").back()
	assert(
		is_equal_approx(float(final_opening.get("gap_height")), 130.0),
		"Spawned obstacles must retain the opening height from their score tier."
	)
	minigame.set("score", 9)
	var obstacle_root: Control = minigame.get("obstacles")[0]["root"]
	obstacle_root.position.x = -20
	minigame.call("_move_obstacles", 0.0)
	assert(minigame.get("score") == 10, "Clearing the tenth obstacle must still award XP.")
	assert(not minigame.get("finished"), "Flight Training must continue beyond ten obstacles.")
	minigame.queue_free()
	var race_background_script: GDScript = load("res://scripts/ui/flight_race_background.gd")
	var moving_background: Control = race_background_script.new()
	moving_background.size = Vector2(720, 1100)
	root.add_child(moving_background)
	await create_timer(0.05).timeout
	assert(
		float(moving_background.get("scroll_offset")) > 0.0,
		"The contest background must scroll continuously instead of remaining static."
	)
	moving_background.queue_free()
	scene.call("_show_flight_training")
	var training_screen: Control = scene.get("screen_router").active_screen
	var training_game: Control
	for child in training_screen.get_children():
		if child.get_script() == flight_game_script:
			training_game = child
			break
	assert(training_game != null, "Flight Training must contain its flight game.")
	assert(
		String(training_game.get("dragon").texture.resource_path).ends_with("ember_flight.png"),
		"Flight Training must use the selected dragon's small flight sprite."
	)
	for score in 50:
		scene.call("_on_flight_score_changed", score + 1)
	assert(game_state.get_flight_level(fire_dragon_id) == 5, "Fifty obstacles in one run must reach Flight Level 5.")
	assert(game_state.can_enter_flight_contest(fire_dragon_id), "Flight Contest must unlock at Level 5.")
	assert(
		game_state.complete_flight_contest(fire_dragon_id, 47) == 0,
		"Finishing behind the best rival must not award gold."
	)
	assert(game_state.flight_contest_wins(fire_dragon_id) == 0, "A lost race must not advance the contest.")
	scene.call("_show_flight_contest")
	assert(scene.get("current_screen") == "flight_contest")
	scene.call("_complete_flight_contest", 50)
	assert(game_state.gold == 1, "A 50 m flight contest must award one gold coin.")
	assert(game_state.flight_contest_wins(fire_dragon_id) == 1, "The first contest win must be saved.")
	assert(game_state.flight_contest_goal(fire_dragon_id) == 70, "The second contest goal must be 70 m.")
	assert(not game_state.can_enter_flight_contest(fire_dragon_id), "The 70 m contest must require more training.")
	assert(
		game_state.get_dragon(fire_dragon_id).get("training_xp", {}).get("flight") == 50,
		"Flight progression must live in the generic per-category XP map."
	)
	assert(
		game_state.purchase_egg("ice").is_empty(),
		"The preserved Frost definition must not be purchasable in the active game flow."
	)
	assert(game_state.gold == 1, "A rejected duplicate egg purchase must not spend gold.")

	var water_egg_id: String = game_state.purchase_egg("water")
	assert(not water_egg_id.is_empty(), "The Water Egg must be purchasable for one gold.")
	assert(game_state.gold == 0, "The Water Egg must cost exactly one gold.")
	game_state.start_incubation(water_egg_id, 0)
	game_state.update_egg_progress(water_egg_id, game_state.EGG_REQUIRED_STEPS)
	assert(game_state.hatch_egg(water_egg_id), "The Water Egg must hatch after 1,000 steps.")
	var water_dragon: Dictionary = game_state.dragons[2]
	assert(water_dragon.get("definition_id") == "marina", "The Water Egg must hatch Marina.")
	assert(game_state.dragon_has_type(water_dragon, &"water"), "Marina must have the water type.")
	scene.call("_select_dragon", String(water_dragon.get("id")))
	habitat_screen = scene.get("screen_router").active_screen
	assert(
		String(habitat_screen.get("active_dragon_texture").resource_path).ends_with("water_dragon_hd.png"),
		"The water dragon must use its own habitat sprite."
	)
	assert(
		String(habitat_screen.get("active_island_texture").resource_path).ends_with("water_island_hd.png"),
		"The water dragon must use its own island."
	)
	game_state.add_flight_xp(fire_dragon_id, 20)
	assert(game_state.can_enter_flight_contest(fire_dragon_id), "Flight Level 7 must unlock the 70 m contest.")
	assert(game_state.complete_flight_contest(fire_dragon_id, 70) == 1, "Winning at 70 m must award one gold.")
	assert(game_state.flight_contest_wins(fire_dragon_id) == 2, "The second contest win must be saved.")
	assert(game_state.flight_contest_goal(fire_dragon_id) == 100, "The third contest goal must be 100 m.")
	var earth_egg_id: String = game_state.purchase_egg("earth")
	assert(not earth_egg_id.is_empty(), "The Earth Egg must be purchasable for one gold.")
	assert(game_state.gold == 0, "The Earth Egg must cost exactly one gold.")
	game_state.start_incubation(earth_egg_id, 0)
	game_state.update_egg_progress(earth_egg_id, game_state.EGG_REQUIRED_STEPS)
	assert(game_state.hatch_egg(earth_egg_id), "The Earth Egg must hatch after 1,000 steps.")
	var earth_dragon: Dictionary = game_state.dragons[3]
	assert(earth_dragon.get("definition_id") == "terra", "The Earth Egg must hatch Terra.")
	assert(game_state.dragon_has_type(earth_dragon, &"earth"), "Terra must have the earth type.")
	assert(game_state.dragon_name_key(earth_dragon) == "EARTH_DRAGON_NAME", "Terra must use its catalog name.")
	scene.call("_select_dragon", String(earth_dragon.get("id")))
	habitat_screen = scene.get("screen_router").active_screen
	assert(
		String(habitat_screen.get("active_dragon_texture").resource_path).ends_with("earth_dragon_hd.png"),
		"The earth dragon must use its own habitat sprite."
	)
	assert(
		String(habitat_screen.get("active_island_texture").resource_path).ends_with("earth_island_hd.png"),
		"The earth dragon must use its own desert island."
	)
	game_state.add_flight_xp(fire_dragon_id, 30)
	assert(game_state.can_enter_flight_contest(fire_dragon_id), "Flight Level 10 must unlock the 100 m contest.")
	assert(game_state.complete_flight_contest(fire_dragon_id, 100) == 1, "Winning at 100 m must award one gold.")
	assert(game_state.flight_contest_wins(fire_dragon_id) == 3, "All three contest wins must be saved.")
	assert(game_state.flight_contest_goal(fire_dragon_id) == 0, "No fourth contest should be offered.")
	assert(not game_state.can_enter_flight_contest(fire_dragon_id), "A champion must not repeat gold races.")
	assert(game_state.fusion_stars == 3, "A new game must include one Fusion Star per recipe.")
	scene.call("_show_fusion")
	assert(scene.get("current_screen") == "fusion", "Fusion must be reachable from the den.")
	var fusion_screen: Control = scene.get("screen_router").active_screen
	fusion_screen.call("debug_select_parents")
	assert(
		game_state.can_fuse(
			String(fire_dragon.get("id")),
			String(water_dragon.get("id"))
		),
		"Ember and Marina must be eligible for fusion."
	)
	fusion_screen.call("debug_begin_trace")
	for letter_index in 6:
		fusion_screen.call("debug_complete_letter")
		await process_frame
		await process_frame
		if letter_index < 5:
			assert(game_state.fusion_stars == 3, "Tracing must not spend a star before the full word.")
	assert(game_state.dragons.size() == 4, "Tracing FUSION must not unlock the dragon immediately.")
	assert(game_state.eggs.size() == 1, "Tracing FUSION must add exactly one Fusion Egg.")
	assert(game_state.fusion_stars == 2, "Completing a fusion must consume one Fusion Star.")
	var fusion_egg: Dictionary = game_state.eggs[0]
	var fusion_egg_id := String(fusion_egg.get("id", ""))
	assert(fusion_egg.get("definition_id") == "voltara", "Fire plus Water must create Voltara's egg.")
	assert(
		fusion_egg.get("required_steps") == game_state.FUSION_EGG_REQUIRED_STEPS,
		"The Fusion Egg must require 5,000 steps."
	)
	assert(
		String(game_state.egg_texture(fusion_egg).resource_path).ends_with("fusion_egg.png"),
		"The Fusion Egg must use its own sprite."
	)
	assert(
		game_state.fusion_eligibility_error(
			String(fire_dragon.get("id")),
			String(water_dragon.get("id"))
		) == &"fusion_pending",
		"A waiting Fusion Egg must block duplicate fusion."
	)
	game_state.start_incubation(fusion_egg_id, 0)
	game_state.update_egg_progress(fusion_egg_id, game_state.EGG_REQUIRED_STEPS)
	assert(not game_state.can_hatch(fusion_egg_id), "The Fusion Egg must not hatch after only 1,000 steps.")
	game_state.update_egg_progress(fusion_egg_id, game_state.FUSION_EGG_REQUIRED_STEPS)
	assert(game_state.hatch_egg(fusion_egg_id), "The Fusion Egg must hatch after 5,000 steps.")
	assert(game_state.eggs.is_empty(), "Hatching must consume the Fusion Egg.")
	assert(game_state.dragons.size() == 5, "Hatching the Fusion Egg must add exactly one dragon.")
	var fusion_dragon: Dictionary = game_state.dragons[4]
	assert(fusion_dragon.get("definition_id") == "voltara", "The Fusion Egg must hatch Voltara.")
	assert(
		game_state.dragon_has_type(fusion_dragon, &"fire")
		and game_state.dragon_has_type(fusion_dragon, &"water"),
		"Voltara must retain both elemental types."
	)
	assert(
		game_state.fusion_eligibility_error(
			String(fire_dragon.get("id")),
			String(water_dragon.get("id"))
		) == &"already_owned",
		"The same fusion dragon must not be creatable twice."
	)
	scene.call("_select_dragon", String(fusion_dragon.get("id")))
	habitat_screen = scene.get("screen_router").active_screen
	assert(
		String(habitat_screen.get("active_dragon_texture").resource_path).ends_with("voltara_dragon_hd.png"),
		"The fusion dragon must use its own habitat sprite."
	)
	assert(
		String(habitat_screen.get("active_island_texture").resource_path).ends_with("voltara_island_hd.png"),
		"The fusion dragon must use its own island."
	)
	var lava_egg_id: String = game_state.fuse_dragons(
		String(fire_dragon.get("id")),
		String(earth_dragon.get("id"))
	)
	assert(not lava_egg_id.is_empty(), "Ember and Terra must create a Fusion Egg.")
	var lava_egg: Dictionary = game_state.get_egg(lava_egg_id)
	assert(lava_egg.get("definition_id") == "lavara", "Fire plus Earth must create Lavara's egg.")
	assert(
		lava_egg.get("required_steps") == game_state.FUSION_EGG_REQUIRED_STEPS,
		"Lavara's Fusion Egg must require 5,000 steps."
	)
	assert(
		String(game_state.egg_texture(lava_egg).resource_path).ends_with("lavara_egg.png"),
		"Lavara's Fusion Egg must use its own sprite."
	)
	assert(game_state.fusion_stars == 1, "The Lava fusion must consume one Fusion Star.")
	game_state.start_incubation(lava_egg_id, 0)
	game_state.update_egg_progress(lava_egg_id, game_state.FUSION_EGG_REQUIRED_STEPS)
	assert(game_state.hatch_egg(lava_egg_id), "Lavara must hatch after 5,000 steps.")
	var lava_dragon: Dictionary = game_state.dragons[5]
	assert(lava_dragon.get("definition_id") == "lavara", "The Lava Fusion Egg must hatch Lavara.")
	scene.call("_select_dragon", String(lava_dragon.get("id")))
	habitat_screen = scene.get("screen_router").active_screen
	assert(
		String(habitat_screen.get("active_dragon_texture").resource_path).ends_with("lavara_dragon_hd.png"),
		"Lavara must use the Lava dragon sprite."
	)
	assert(
		String(habitat_screen.get("active_island_texture").resource_path).ends_with("lavara_island_hd.png"),
		"Lavara must use the volcanic desert island."
	)
	var mud_egg_id: String = game_state.fuse_dragons(
		String(water_dragon.get("id")),
		String(earth_dragon.get("id"))
	)
	assert(not mud_egg_id.is_empty(), "Marina and Terra must create a Fusion Egg.")
	var mud_egg: Dictionary = game_state.get_egg(mud_egg_id)
	assert(mud_egg.get("definition_id") == "mudara", "Earth plus Water must create Mudara's egg.")
	assert(
		mud_egg.get("required_steps") == game_state.FUSION_EGG_REQUIRED_STEPS,
		"Mudara's Fusion Egg must require 5,000 steps."
	)
	assert(
		String(game_state.egg_texture(mud_egg).resource_path).ends_with("mudara_egg.png"),
		"Mudara's Fusion Egg must use its own sprite."
	)
	assert(game_state.fusion_stars == 0, "The Mud fusion must consume the final Fusion Star.")
	game_state.start_incubation(mud_egg_id, 0)
	game_state.update_egg_progress(mud_egg_id, game_state.FUSION_EGG_REQUIRED_STEPS)
	assert(game_state.hatch_egg(mud_egg_id), "Mudara must hatch after 5,000 steps.")
	var mud_dragon: Dictionary = game_state.dragons[6]
	assert(mud_dragon.get("definition_id") == "mudara", "The Mud Fusion Egg must hatch Mudara.")
	scene.call("_select_dragon", String(mud_dragon.get("id")))
	habitat_screen = scene.get("screen_router").active_screen
	assert(
		String(habitat_screen.get("active_dragon_texture").resource_path).ends_with("mudara_dragon_hd.png"),
		"Mudara must use the Mud dragon sprite."
	)
	assert(
		String(habitat_screen.get("active_island_texture").resource_path).ends_with("mudara_island_hd.png"),
		"Mudara must use the marsh island."
	)
	assert(
		game_state.serialize_state().get("schema_version") == game_state.SAVE_SCHEMA_VERSION,
		"Saves must declare the current schema version."
	)
	game_state.load_payload({
		"schema_version": 4,
		"currencies": {"gems": 125, "gold": 1, "fusion_stars": 0},
		"dragons": [
			{"id": "schema-four-luma", "definition_id": "luma", "starter": true},
		],
		"eggs": [],
	})
	assert(
		game_state.fusion_stars == 2,
		"Schema 4 saves must receive one star for each newly added fusion recipe."
	)
	game_state.load_payload({
		"schema_version": 3,
		"currencies": {"gems": 125, "gold": 0, "fusion_stars": 0},
		"dragons": [
			{"id": "luma", "definition_id": "luma", "starter": true},
			{"id": "old-ember", "definition_id": "ember"},
			{"id": "old-marina", "definition_id": "marina"},
			{"id": "old-direct-voltara", "definition_id": "voltara"},
		],
		"eggs": [],
	})
	assert(
		game_state.get_dragon("old-direct-voltara").is_empty(),
		"Schema 3 saves must migrate directly granted Voltara back into its Fusion Egg."
	)
	assert(
		game_state.eggs.size() == 1
		and game_state.eggs[0].get("definition_id") == "voltara"
		and game_state.eggs[0].get("required_steps") == game_state.FUSION_EGG_REQUIRED_STEPS,
		"The direct-fusion save migration must create a fresh 5,000-step Fusion Egg."
	)
	assert(game_state.fusion_stars == 2, "Schema 3 saves must gain the two newly added Fusion Stars.")
	game_state.load_payload({
		"hunger": 81,
		"cleanliness": 72.0,
		"care_points": 33,
		"gems": 9,
		"gold": 2,
		"dragons": [
			{
				"id": "luma",
				"name_key": "DRAGON_NAME",
				"species": "sunwing",
				"starter": true,
				"flight_xp": 4,
			},
			{
				"id": "legacy-frost",
				"name_key": "ICE_DRAGON_NAME",
				"species": "ice",
				"starter": false,
				"flight_xp": 17,
			},
			{
				"id": "legacy-second-sunwing",
				"name_key": "HATCHED_DRAGON_NAME",
				"species": "sunwing",
				"starter": false,
				"flight_xp": 23,
				"hunger": 91,
			},
		],
		"eggs": [
			{"id": "legacy-sunwing-egg", "kind": "sunwing"},
			{"id": "pending-fire-a", "definition_id": "ember"},
			{"id": "pending-fire-b", "definition_id": "ember"},
		],
	})
	assert(game_state.dragons.size() == 2, "Duplicate dragon types in legacy saves must be collapsed.")
	assert(game_state.get_dragon("luma").get("definition_id") == "luma", "The starter must win a duplicate type conflict.")
	assert(game_state.get_training_xp("luma", &"flight") == 23, "Duplicate cleanup must preserve the highest training XP.")
	assert(game_state.get_dragon_hunger("luma") == 91, "Duplicate cleanup must preserve the highest care values.")
	assert(game_state.get_dragon("legacy-frost").get("definition_id") == "frost", "Legacy species must migrate to definitions.")
	assert(game_state.get_training_xp("legacy-frost", &"flight") == 17, "Legacy Flight XP must migrate by category.")
	assert(game_state.get_dragon_hunger("legacy-frost") == 81, "Legacy shared care must migrate onto each dragon.")
	assert(game_state.eggs.size() == 1, "Owned and duplicate pending dragon types must be removed.")
	assert(game_state.eggs[0].get("definition_id") == "ember", "One valid pending Fire Egg must remain.")
	assert(game_state.serialize_state().get("currencies", {}).get("fusion_stars") == 3, "Legacy saves must gain all three Fusion Stars.")

	scene.call("_show_settings")
	assert(scene.get("current_screen") == "settings", "Settings must be reachable from the main flow.")
	var settings_screen: Control = scene.get("screen_router").active_screen
	settings_screen.call("_on_reset_pressed")
	assert(scene.get("current_screen") == "settings", "Reset must require a second confirmation press.")
	settings_screen.call("_on_reset_pressed")
	assert(scene.get("current_screen") == "main", "Confirmed reset must return to the starting screen.")
	assert(game_state.dragons.size() == 1, "Reset must restore the single starter dragon.")
	assert(game_state.dragons[0].get("definition_id") == "luma", "Reset must restore Luma.")
	assert(game_state.eggs.is_empty(), "Reset must remove every egg.")
	assert(game_state.gems == 125 and game_state.gold == 0, "Reset must restore starting currencies.")
	assert(game_state.fusion_stars == 3, "Reset must restore all starting Fusion Stars.")

	print("Gameplay smoke test: valid")
	quit()
