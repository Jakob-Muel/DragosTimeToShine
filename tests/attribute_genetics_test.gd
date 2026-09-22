extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	state.reset_for_tests()
	var a := "luma"
	var b: String = state.unlock_dragon(&"luma", "second-parent")
	assert(not b.is_empty(), "Same-type dragons must be allowed.")
	var pa: Dictionary = state.get_dragon(a)
	var pb: Dictionary = state.get_dragon(b)
	pa.attributes = {"attack_power": {"value": 75, "potential": 80}, "attack_speed": {"value": 20, "potential": 40}, "movement_speed": {"value": 55, "potential": 65}}
	pb.attributes = {"attack_power": {"value": 20, "potential": 30}, "attack_speed": {"value": 85, "potential": 90}, "movement_speed": {"value": 40, "potential": 50}}
	var parents_before: Array = state.dragons.duplicate(true)
	var sources := {"attack_power": a, "attack_speed": b, "movement_speed": a}
	var stars: int = state.fusion_stars
	assert(state.fuse_dragons(a, b, {"attack_power": "not-a-parent"}).is_empty())
	assert(state.fusion_stars == stars and state.eggs.is_empty())
	assert(state.fuse_dragons(a, a).is_empty())
	var egg_id: String = state.fuse_dragons(a, b, sources)
	assert(not egg_id.is_empty())
	assert(state.dragons == parents_before)
	var egg: Dictionary = state.get_egg(egg_id).duplicate(true)
	assert(egg.attributes.attack_power.potential == 80)
	assert(egg.attributes.attack_speed.potential == 90)
	assert(egg.attributes.movement_speed.potential == 65)
	state.load_payload(state.serialize_state())
	assert(state.get_egg(egg_id) == egg)
	state.update_egg_progress(egg_id, 5000)
	assert(state.hatch_egg(egg_id))
	var child: Dictionary = state.dragons.back()
	assert(child.generation == 1 and child.parent_ids == [a, b] and child.inheritance == sources)
	for attr: String in state.ATTRIBUTES.IDS:
		assert(child.attributes[attr].value == 10, "No training is inherited.")
	var result: Dictionary = state.create_training_session(child.id, &"element_power")
	result.raw_score = 10000
	var summary: Dictionary = state.apply_training_result(child.id, result, "attack_speed")
	assert(summary.accepted and summary.attribute_gain == 80)
	assert(state.get_dragon(child.id).attributes.attack_speed.value == 90)
	assert(state.get_dragon(child.id).attributes.attack_power.value == 10)
	assert(not state.apply_training_result(child.id, result, "attack_power").accepted)
	var flight: Dictionary = state.create_training_session(child.id, &"flight")
	flight.raw_score = 5
	assert(state.apply_training_result(child.id, flight).attribute_gain > 0)
	var second_egg: String = state.fuse_dragons(child.id, b, {"attack_power": child.id, "attack_speed": child.id, "movement_speed": b})
	assert(not second_egg.is_empty(), "Children can breed again.")
	state.update_egg_progress(second_egg, 5000)
	assert(state.hatch_egg(second_egg))
	assert(state.dragons.back().generation == 2)
	assert(state.dragons.back().attributes.attack_speed.value == 10)
	assert(state.dragons.back().attributes.movement_speed.potential == 50)
	var saved: Dictionary = state.serialize_state()
	state.load_payload(saved)
	assert(state.serialize_state() == saved)
	var legacy := saved.duplicate(true)
	legacy["schema_version"] = 10
	legacy["dragons"][0].erase("attributes")
	state.load_payload(legacy)
	assert(state.dragons.size() == saved.dragons.size())
	var migrated: Dictionary = state.dragon_attributes(a)
	state.load_payload(state.serialize_state())
	assert(state.dragon_attributes(a) == migrated, "Migration potentials must remain stable.")
	state.gold = 10
	assert(not state.purchase_egg().is_empty(), "Owned types do not exhaust the shop.")
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("_show_attributes")
	assert(scene.current_screen == "attributes")
	scene.call("_show_fusion")
	var screen: Control = scene.screen_router.active_screen
	screen.first_parent_id = a
	screen.second_parent_id = b
	screen.call("_build_inheritance")
	var selectors: Array = []
	_find_selectors(screen, selectors)
	assert(selectors.size() == 3)
	selectors[1].item_selected.emit(1)
	assert(screen.inheritance.attack_power == a and screen.inheritance.attack_speed == b and screen.inheritance.movement_speed == a)
	print("Attribute genetics: valid (caps, targeted training, inheritance UI, fresh offspring, generations, repeat purchase, reload)")
	quit()

func _find_selectors(node: Node, found: Array) -> void:
	if node is OptionButton:
		found.append(node)
	for child in node.get_children():
		_find_selectors(child, found)
