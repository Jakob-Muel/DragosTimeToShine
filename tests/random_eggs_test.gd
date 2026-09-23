extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	var outcomes := {}
	for trial in 60:
		state.reset_for_tests()
		state.gold = 20
		for old_kind in ["fire", "water", "earth", "ice"]:
			assert(not state.can_purchase_egg(old_kind))
		var reserved := {}
		for index in 4:
			var egg_id: String = state.purchase_egg()
			assert(not egg_id.is_empty())
			var egg: Dictionary = state.get_egg(egg_id)
			assert(egg.attributes.size() == 3)
			reserved[egg.definition_id] = true
			if index == 0:
				outcomes[egg.definition_id] = true
			assert(egg.required_steps == 5000)
			assert(state.egg_name_key(egg) == "RANDOM_EGG_NAME")
			assert(state.egg_texture(egg).resource_path.ends_with("sun_egg.png"))
		assert(state.can_purchase_egg(), "New individuals remain purchasable.")
		assert(state.gold == 16)
		var before: Array = state.eggs.duplicate(true)
		state.load_payload(state.serialize_state())
		assert(state.eggs == before, "Reload must not reroll reserved dragons or appearance.")
		var egg_id: String = state.eggs[0].id
		var appearance: int = state.eggs[0].appearance_seed
		state.start_incubation(egg_id, 0)
		state.update_egg_progress(egg_id, 4999)
		assert(not state.hatch_egg(egg_id))
		state.update_egg_progress(egg_id, 5000)
		assert(state.hatch_egg(egg_id))
		assert(state.dragons.back().appearance_seed == appearance)
	assert(outcomes.size() > 1, "Eggs must not always select the same definition.")
	state.reset_for_tests()
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("_show_den")
	assert(_shop_buttons(scene.screen_router.active_screen) == 0)
	scene.call("_show_eggs")
	assert(_shop_buttons(scene.screen_router.active_screen) == 0)
	scene.call("_show_main_menu")
	assert(_shop_buttons(scene.screen_router.active_screen) == 1)
	print("Random eggs: valid (variety, individual potentials, no rerolls, step boundary, one shop entry)")
	quit()

func _shop_buttons(node: Node) -> int:
	var count := 0
	if (node is Button or node is Label) and node.text == TranslationServer.translate("NAV_SHOP"):
		count += 1
	for child in node.get_children():
		count += _shop_buttons(child)
	return count
