extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset_for_tests()
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	_assert_route(scene, "main")
	scene.call("_show_den")
	_assert_route(scene, "den")
	scene.call("_show_shop")
	_assert_route(scene, "shop")
	scene.call("_show_settings")
	_assert_route(scene, "settings")
	scene.call("_show_fusion")
	_assert_route(scene, "fusion")
	scene.call("_show_dragons")
	_assert_route(scene, "dragons")
	scene.call("_show_eggs")
	_assert_route(scene, "eggs")
	scene.call("_show_habitat")
	_assert_route(scene, "habitat")
	scene.call("_show_grooming")
	_assert_route(scene, "groom")
	scene.call("_show_competition")
	_assert_route(scene, "flight_select")
	scene.call("_show_flight_hub")
	_assert_route(scene, "flight_hub")
	scene.call("_show_flight_training")
	_assert_route(scene, "flight_training")
	game_state.add_flight_xp(
		"luma",
		game_state.FLIGHT_CONTEST_LEVEL * game_state.FLIGHT_XP_PER_LEVEL
	)
	scene.call("_show_flight_contest")
	_assert_route(scene, "flight_contest")

	print("Screen routing test: valid")
	quit()


func _assert_route(scene: Control, expected: String) -> void:
	var router: ScreenRouter = scene.get("screen_router")
	assert(scene.get("current_screen") == expected, "Main route must match %s." % expected)
	assert(router.current_route == expected, "Router must match %s." % expected)
	assert(is_instance_valid(router.active_screen), "%s must have an active scene." % expected)
