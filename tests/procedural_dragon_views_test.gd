extends SceneTree
## requires-graphics
const TEXTURES := preload("res://scripts/ui/procedural_dragon_textures.gd")
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "This regression needs a graphics device.")
	var seed := TEXTURES.seed_for({"id":"stable-dragon"})
	assert(seed == TEXTURES.seed_for({"id":"stable-dragon","hunger":99}))
	assert(seed != TEXTURES.seed_for({"id":"another-dragon"}))
	assert(TEXTURES.seed_for({"id":"stable-dragon","appearance_seed":77}) == 77)
	var textures: Array[Texture2D] = []
	for value in [34,37,2,77]:
		for pose: String in ["portrait","flight","overhead"]:
			var texture := TEXTURES.texture_for(value,pose)
			assert(texture == TEXTURES.texture_for(value,pose), "Same seed and pose must reuse the texture.")
			textures.append(texture)
	for frame in 180:
		if TEXTURES.pending_renders == 0:
			break
		await process_frame
	assert(TEXTURES.pending_renders == 0, "All queued views must finish.")
	var hashes := {}
	for texture in textures:
		assert(texture.get_meta("procedural_ready",false))
		var image := texture.get_image()
		assert(image.get_pixel(0,0).a < 0.01, "Views need transparent margins.")
		var bounds := image.get_used_rect()
		assert(bounds.size.x > image.get_width()*0.4 and bounds.size.y > image.get_height()*0.4)
		var fingerprint := image.get_data().hex_encode().sha256_text()
		assert(not hashes.has(fingerprint), "Different seeds and poses must render differently.")
		hashes[fingerprint] = true
	await process_frame
	assert(TEXTURES._instance.get_child_count() == 0, "One-shot render viewports must be released.")
	var game := preload("res://scripts/ui/flame_shooter_game.gd").new()
	game.size = Vector2(720,1200)
	game.configure({"appearance":{"seed":77}})
	root.add_child(game)
	assert(game.dragon.texture.get_meta("dragon_seed") == 77)
	assert(game.dragon.texture.get_meta("dragon_pose") == "overhead")
	assert(game.DRAGON_SIZE.x < 130 and game.KNIGHT_SIZE.x < 80 and game.FLAME_SIZE.x < 32)
	assert(game.dragon.size == game.DRAGON_SIZE, "Texture resolution must not enlarge the on-screen dragon.")
	game.debug_spawn_knight()
	game.debug_fire()
	assert(game.knights[0]["root"].size == game.KNIGHT_SIZE)
	assert(game.projectiles[0]["root"].size == game.FLAME_SIZE)
	game.free()
	print("Procedural dragon views: valid (12 distinct renders, stable identity, reused textures, released viewports, shooter seed and scale)")
	quit()
