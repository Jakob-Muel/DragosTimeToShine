extends SceneTree


func _init() -> void:
	var catalog := GameCatalog.new()
	var collection := CollectionService.new(catalog)
	var fusion := FusionService.new(catalog, collection)

	assert(catalog.egg_candidates(&"fire") == [&"ember"], "The Fire Egg pool must contain Ember.")
	assert(catalog.egg_candidates(&"water") == [&"marina"], "The Water Egg pool must contain Marina.")
	assert(catalog.egg_candidates(&"earth") == [&"terra"], "The Earth Egg pool must contain Terra.")
	assert(catalog.egg_candidates(&"ice") == [&"frost"], "Frost must remain preserved in the catalog.")
	var luma := catalog.get_dragon(&"luma")
	assert(luma.flight_texture_path.ends_with("flight_dragon.png"), "Luma must keep her flight sprite.")
	var frost := catalog.get_dragon(&"frost")
	assert(frost.flight_texture_path.ends_with("frost_flight.png"), "Frost needs its own flight sprite.")
	var ember := catalog.get_dragon(&"ember")
	var marina := catalog.get_dragon(&"marina")
	assert(ember.dragon_texture_path.ends_with("fire_dragon_hd.png"), "Ember needs its own sprite.")
	assert(ember.island_texture_path.ends_with("fire_island_hd.png"), "Ember needs its own island.")
	assert(ember.flight_texture_path.ends_with("ember_flight.png"), "Ember needs its own flight sprite.")
	assert(marina.dragon_texture_path.ends_with("water_dragon_hd.png"), "Marina needs its own sprite.")
	assert(marina.island_texture_path.ends_with("water_island_hd.png"), "Marina needs its own island.")
	assert(marina.flight_texture_path.ends_with("marina_flight.png"), "Marina needs its own flight sprite.")
	var terra := catalog.get_dragon(&"terra")
	assert(terra != null and terra.has_type(&"earth"), "Terra must be registered as an Earth Dragon.")
	assert(terra.egg_texture_path.ends_with("earth_egg.png"), "Terra needs its own egg sprite.")
	assert(terra.dragon_texture_path.ends_with("earth_dragon_hd.png"), "Terra needs its own sprite.")
	assert(terra.island_texture_path.ends_with("earth_island_hd.png"), "Terra needs its own desert island.")
	assert(terra.flight_texture_path.ends_with("terra_flight.png"), "Terra needs its own flight sprite.")
	var voltara := catalog.get_dragon(&"voltara")
	assert(voltara != null, "The Fire-Water fusion dragon must be registered.")
	assert(voltara.has_type(&"fire") and voltara.has_type(&"water"), "Voltara must have both parent types.")
	assert(voltara.egg_kind == &"fusion", "Voltara must hatch from a Fusion Egg.")
	assert(voltara.egg_texture_path.ends_with("fusion_egg.png"), "Voltara needs its own Fusion Egg sprite.")
	assert(voltara.dragon_texture_path.ends_with("voltara_dragon_hd.png"), "Voltara needs its own sprite.")
	assert(voltara.island_texture_path.ends_with("voltara_island_hd.png"), "Voltara needs its own island.")
	assert(voltara.flight_texture_path.ends_with("voltara_flight.png"), "Voltara needs its own flight sprite.")
	var lavara := catalog.get_dragon(&"lavara")
	assert(lavara != null, "The Fire-Earth fusion dragon must be registered.")
	assert(lavara.has_type(&"fire") and lavara.has_type(&"earth"), "Lavara must have both parent types.")
	assert(lavara.egg_kind == &"fusion", "Lavara must hatch from a Fusion Egg.")
	assert(lavara.egg_texture_path.ends_with("lavara_egg.png"), "Lavara needs its own Fusion Egg sprite.")
	assert(lavara.dragon_texture_path.ends_with("lavara_dragon_hd.png"), "Lavara needs its own sprite.")
	assert(lavara.island_texture_path.ends_with("lavara_island_hd.png"), "Lavara needs its own island.")
	assert(lavara.flight_texture_path.ends_with("lavara_flight.png"), "Lavara needs its own flight sprite.")
	var mudara := catalog.get_dragon(&"mudara")
	assert(mudara != null, "The Earth-Water fusion dragon must be registered.")
	assert(mudara.has_type(&"earth") and mudara.has_type(&"water"), "Mudara must have both parent types.")
	assert(mudara.egg_kind == &"fusion", "Mudara must hatch from a Fusion Egg.")
	assert(mudara.egg_texture_path.ends_with("mudara_egg.png"), "Mudara needs its own Fusion Egg sprite.")
	assert(mudara.dragon_texture_path.ends_with("mudara_dragon_hd.png"), "Mudara needs its own sprite.")
	assert(mudara.island_texture_path.ends_with("mudara_island_hd.png"), "Mudara needs its own island.")
	assert(mudara.flight_texture_path.ends_with("mudara_flight.png"), "Mudara needs its own flight sprite.")
	var production_recipe := catalog.get_fusion_recipe(&"ember", &"marina")
	assert(production_recipe != null, "Ember and Marina must have a fusion recipe.")
	assert(production_recipe.result == &"voltara", "Ember plus Marina must create Voltara's Fusion Egg.")
	assert(production_recipe.fusion_star_cost == 1, "The production fusion must cost one star.")
	var lava_recipe := catalog.get_fusion_recipe(&"terra", &"ember")
	assert(lava_recipe != null, "Ember and Terra must have a fusion recipe.")
	assert(lava_recipe.result == &"lavara", "Ember plus Terra must create Lavara's Fusion Egg.")
	assert(lava_recipe.fusion_star_cost == 1, "The Lava fusion must cost one star.")
	var mud_recipe := catalog.get_fusion_recipe(&"terra", &"marina")
	assert(mud_recipe != null, "Terra and Marina must have a fusion recipe.")
	assert(mud_recipe.result == &"mudara", "Terra plus Marina must create Mudara's Fusion Egg.")
	assert(mud_recipe.fusion_star_cost == 1, "The Mud fusion must cost one star.")

	var frost_egg := collection.next_unowned_egg(
		&"ice",
		[{"id": "luma", "definition_id": "luma"}],
		[]
	)
	assert(frost_egg == &"frost", "The ice egg pool must offer the unowned Frost definition.")
	assert(
		collection.next_unowned_egg(
			&"ice",
			[{"id": "frost-owned", "definition_id": "frost"}],
			[]
		).is_empty(),
		"Owned dragon definitions must be excluded from egg rewards."
	)
	assert(
		collection.next_unowned_egg(
			&"ice",
			[{"id": "luma", "definition_id": "luma"}],
			[{"id": "pending-frost", "definition_id": "frost"}]
		).is_empty(),
		"Pending eggs must reserve their dragon definition."
	)

	var fire := DragonDefinition.new()
	fire.id = &"fire-test"
	fire.name_key = &"DRAGON_NAME"
	fire.types = [&"fire"]
	catalog.register_dragon(fire)
	var hybrid := DragonDefinition.new()
	hybrid.id = &"ice-fire-test"
	hybrid.name_key = &"DRAGON_NAME"
	hybrid.types = [&"ice", &"fire"]
	catalog.register_dragon(hybrid)
	var recipe := FusionRecipe.new()
	recipe.parent_a = &"frost"
	recipe.parent_b = &"fire-test"
	recipe.result = &"ice-fire-test"
	recipe.fusion_star_cost = 2
	catalog.register_fusion_recipe(recipe)

	var frost_parent := {
		"id": "frost-parent",
		"definition_id": "frost",
		"hunger": 100,
		"cleanliness": 100.0,
	}
	var fire_parent := {
		"id": "fire-parent",
		"definition_id": "fire-test",
		"hunger": 100,
		"cleanliness": 100.0,
	}
	var parents: Array[Dictionary] = [frost_parent, fire_parent]
	assert(fusion.can_fuse(frost_parent, fire_parent, parents, 2), "A ready pair with a recipe must be eligible.")
	assert(fusion.result_for(fire_parent, frost_parent) == &"ice-fire-test", "Fusion pairing must be order-independent.")
	assert(
		fusion.eligibility_error(frost_parent, fire_parent, parents, 1) == &"not_enough_stars",
		"Fusion must require its Fusion Star cost."
	)
	fire_parent["cleanliness"] = 20.0
	assert(
		fusion.can_fuse(frost_parent, fire_parent, parents, 2),
		"Fusion eligibility must depend on the pair and Fusion Stars, not care state."
	)

	var trace_pad_script: GDScript = load("res://scripts/ui/letter_trace_pad.gd")
	var trace_pad: Control = trace_pad_script.new()
	trace_pad.size = Vector2(600, 720)
	for letter in ["F", "U", "S", "I", "O", "N"]:
		trace_pad.call("set_letter", letter)
		for stroke: PackedVector2Array in trace_pad.get("guide_strokes"):
			trace_pad.call("_handle_pointer", stroke[0], true)
			for point: Vector2 in stroke:
				trace_pad.call("_extend_trace", point)
			trace_pad.call("_handle_pointer", stroke[-1], false)
		assert(trace_pad.get("completed"), "%s must complete when its full guide is traced." % letter)
	trace_pad.call("set_letter", "F")
	trace_pad.call("_handle_pointer", Vector2(5, 5), true)
	trace_pad.call("_extend_trace", Vector2(30, 30))
	trace_pad.call("_handle_pointer", Vector2(30, 30), false)
	assert(not trace_pad.get("completed"), "A stroke away from the guide must not complete a letter.")
	trace_pad.free()

	print("Domain rules test: valid")
	quit()
