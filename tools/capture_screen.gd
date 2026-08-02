extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var screen_name := args[0] if not args.is_empty() else "main"
	var profile := args[1] if args.size() > 1 else "iphone_pro"
	var target_size := Vector2i(1179, 2556)
	match profile:
		"desktop":
			target_size = Vector2i(393, 852)
		"iphone_se":
			target_size = Vector2i(750, 1334)
		"android":
			target_size = Vector2i(1080, 2400)
		"android_compact":
			target_size = Vector2i(1080, 2160)
	var output_suffix := "" if args.size() <= 1 else "_" + profile
	var output := "res://docs/screenshots/%s%s.png" % [screen_name, output_suffix]
	var display_screen := screen_name
	var capture_locale := ""
	var game_state := root.get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_for_tests()
	if screen_name.ends_with("_de"):
		display_screen = screen_name.trim_suffix("_de")
		capture_locale = "de"
	var capture_viewport := SubViewport.new()
	capture_viewport.size = target_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	var packed_scene: PackedScene = load("res://main.tscn")
	var scene: Node = packed_scene.instantiate()
	capture_viewport.add_child(scene)
	await process_frame
	await process_frame
	if not capture_locale.is_empty():
		scene.call("debug_set_locale", capture_locale)
		await process_frame
	scene.call("debug_show_screen", display_screen)
	await process_frame
	await process_frame
	if display_screen == "fed":
		scene.call("debug_show_screen", "habitat")
		await process_frame
		scene.call("_feed_dragon")
		await create_timer(3.5).timeout
	elif display_screen == "groomed":
		await create_timer(0.12).timeout
	elif display_screen == "fusion_trace":
		await create_timer(0.12).timeout
	elif display_screen in ["flight_contest", "result"]:
		await create_timer(1.15).timeout
	var image := capture_viewport.get_texture().get_image()
	var error := image.save_png(output)
	if error != OK:
		push_error("Could not save screenshot: %s" % error)
		quit(1)
		return
	print("Saved " + output)
	quit()
