extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	state.reset_for_tests(false)
	assert(state.dragons.is_empty() and state.eggs.size() == 1)
	assert(state.gold == 0 and state.can_hatch("starter-egg"))
	assert(state.purchase_egg().is_empty())
	var pending: Dictionary = state.serialize_state()
	pending["schema_version"] = 8
	state.load_payload(pending)
	assert(state.dragons.is_empty() and state.starter_egg_id() == "starter-egg")
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.current_screen == "egg_detail")
	var screen: Control = scene.screen_router.active_screen
	screen.hatch()
	screen.hatch()
	assert(state.dragons.size() == 1 and state.eggs.is_empty())
	assert(state.get_dragon("luma").starter)
	assert(not state.hatch_egg("starter-egg"))
	await create_timer(1.7).timeout
	assert(scene.current_screen == "habitat")
	state.load_payload(state.serialize_state())
	assert(state.starter_egg_id().is_empty() and state.dragons.size() == 1)
	assert(state.get_dragon("luma").appearance_seed > 0)
	assert(state.complete_flight_contest("luma") == 0)
	state.add_flight_xp("luma", 50)
	assert(state.complete_flight_contest("luma") == 1)
	var egg_id: String = state.purchase_egg()
	assert(not egg_id.is_empty() and state.gold == 0)
	assert(not state.can_hatch(egg_id) and not state.hatch_egg(egg_id))
	assert(state.get_egg(egg_id).required_steps == 5000)
	state.start_incubation(egg_id, 0)
	state.update_egg_progress(egg_id, 750)
	var legacy: Dictionary = state.serialize_state()
	legacy["schema_version"] = 8
	legacy["eggs"][0]["required_steps"] = 1000
	state.load_payload(legacy)
	assert(state.get_egg(egg_id).required_steps == 5000)
	assert(state.get_egg(egg_id).progress_steps == 750)
	state.update_egg_progress(egg_id, 1000)
	assert(not state.can_hatch(egg_id))
	state.update_egg_progress(egg_id, 4999)
	assert(not state.can_hatch(egg_id))
	state.update_egg_progress(egg_id, 5000)
	assert(state.hatch_egg(egg_id))
	assert(state.dragons.size() == 2 and state.eggs.is_empty())
	var seed: int = state.dragons[1].appearance_seed
	state.load_payload(state.serialize_state())
	assert(state.dragons[1].appearance_seed == seed)
	assert(not state.hatch_egg(egg_id))
	print("Starter progression: valid (onboarding, reload, one-time hatch, training, gold, purchase, walking, appearance)")
	quit()
