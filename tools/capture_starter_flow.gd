extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("GameState").reset_for_tests(false)
	root.size = Vector2i(720, 1280)
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/starter_egg.png")
	scene.screen_router.active_screen.hatch()
	await create_timer(2.0).timeout
	while ProceduralDragonTextures.pending_renders > 0:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/starter_dragon.png")
	quit()
