extends SceneTree

## Capture the real screens with deterministic demo state, without touching saves.
const SCREENS := ["main", "habitat", "shop", "dragons_elements", "settings", "groom", "ice_island", "fire_island", "water_island", "earth_island", "fusion_island", "lava_island", "mud_island", "flight_training_water", "flight_contest", "flame_shooter", "fusion_trace", "fire_egg", "ice_egg", "flight_hub", "dragon_lab"]

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var short_phone := OS.get_cmdline_user_args().has("short")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(750, 1334) if short_phone else Vector2i(720, 1565)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var review_screens: Array = ["main", "habitat", "shop", "flight_training_water", "flame_shooter", "settings"] if short_phone else SCREENS
	for screen: String in review_screens:
		root.get_node("GameState").reset_for_tests()
		var scene := load("res://main.tscn").instantiate() as Node
		viewport.add_child(scene)
		await process_frame
		await process_frame
		scene.call("debug_show_screen", screen)
		for frame in 6:
			await process_frame
		if screen == "flight_contest":
			await create_timer(0.6).timeout
		for pending_frame in 120:
			if ProceduralDragonTextures.pending_renders == 0:
				break
			await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png("res://docs/screenshots/comic/" + screen + ("_short" if short_phone else "") + ".png") == OK)
		print("Captured ", screen)
		scene.queue_free()
		await process_frame
	if not short_phone:
		await _overview()
	quit()


func _overview() -> void:
	var board := SubViewport.new()
	board.size = Vector2i(1600, 962)
	board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#e7eee6")
	backdrop.size = board.size
	board.add_child(backdrop)
	var title := WidgetFactory.label("DRAGO’S · COMIC EDITION", 36, UiTokens.INK, HORIZONTAL_ALIGNMENT_LEFT, UiTokens.FONT_HEAVY)
	title.position = Vector2(30, 15)
	title.size = Vector2(1540, 55)
	board.add_child(title)
	var screens := ["main", "shop", "flight_training_water", "flame_shooter"]
	var captions := ["A WARMER WORLD", "ELEMENTAL EGGS", "FLIGHT & PARALLAX", "FLAME RUN"]
	for index in screens.size():
		var label := WidgetFactory.label(captions[index], 19, UiTokens.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD)
		label.position = Vector2(30 + index * 393, 79)
		label.size = Vector2(360, 35)
		board.add_child(label)
		var panel := Panel.new()
		panel.position = Vector2(28 + index * 393, 120)
		panel.size = Vector2(364, 787)
		panel.add_theme_stylebox_override("panel", WidgetFactory._flat_panel_style(UiTokens.INK, UiTokens.INK, 4, 5, Color("#382b3d33")))
		board.add_child(panel)
		var art := ImageTexture.create_from_image(Image.load_from_file("res://docs/screenshots/comic/" + screens[index] + ".png"))
		var screenshot := WidgetFactory.texture_rect(art, Rect2(2, 2, 360, 782.5), TextureRect.STRETCH_SCALE)
		panel.add_child(screenshot)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(board.get_texture().get_image().save_png("res://docs/screenshots/comic/overview.png") == OK)
	print("Captured overview")
