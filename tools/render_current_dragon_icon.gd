extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var texture := ProceduralDragonTextures.texture_for(34)
	while ProceduralDragonTextures.pending_renders > 0:
		await process_frame
	assert(texture.get_image().save_png("res://assets/art/current_dragon.png") == OK)
	quit()
