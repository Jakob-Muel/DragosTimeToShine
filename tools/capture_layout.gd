extends SceneTree

## Captures one screen at an arbitrary window size, for layout review by humans and agents.
## Needs a rendering device (on Linux: xvfb-run). Never touches the player's save.
##
##   godot --path . --script tools/capture_layout.gd -- <scenario> <width> <height> <locale> <output.png>
##
## Scenarios: "main", "starter_egg" (first launch, egg not hatched yet), or any name
## accepted by main.gd debug_show_screen (den, shop, habitat, groom, egg, fusion, ...).


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := args[0] if args.size() > 0 else "main"
	var target := Vector2i(int(args[1]) if args.size() > 1 else 1179, int(args[2]) if args.size() > 2 else 2556)
	var locale := args[3] if args.size() > 3 else "en"
	var output := args[4] if args.size() > 4 else "/tmp/%s_%dx%d_%s.png" % [scenario, target.x, target.y, locale]

	var game_state := root.get_node("GameState")
	game_state.reset_for_tests(scenario != "starter_egg")
	var viewport := SubViewport.new()
	viewport.size = target
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node = load("res://main.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame
	scene.call("debug_set_locale", locale)
	await process_frame
	match scenario:
		"main":
			scene.call("_show_main_menu")
		"starter_egg":
			scene.call("_show_egg_detail", String(game_state.starter_egg_id()), false)
		_:
			scene.call("debug_show_screen", scenario)
	for frame in 150:
		if ProceduralDragonTextures.pending_renders == 0 and frame > 3:
			break
		await process_frame
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Could not save screenshot: %s" % error)
		quit(1)
		return
	print("Saved " + output)
	quit()
