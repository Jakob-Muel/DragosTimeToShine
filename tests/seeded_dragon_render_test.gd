extends SceneTree
## requires-graphics

## Run with a rendering device (without --headless):
## Godot --path . --script tests/seeded_dragon_render_test.gd
## Checks actual portraits, including material/cache paths absent from trait tests.
const DRAGON := preload("res://scripts/ui/seeded_dragon.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 360)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var dragon := DRAGON.new()
	dragon.animate = false
	dragon.size = viewport.size
	viewport.add_child(dragon)
	var signatures := {}
	var reference := 0
	for seed_value in range(1, 101):
		dragon.set_seed(seed_value)
		for far in [true, false]:
			var arm: PackedVector2Array = dragon._arm_geometry(far)["points"]
			assert(not Geometry2D.triangulate_polygon(arm).is_empty(), "Shoulder curves must not intersect themselves.")
		assert(not Geometry2D.triangulate_polygon(dragon._torso_points()).is_empty(), "Joined torso must be a valid continuous surface.")
		await process_frame
		await process_frame
		var image := viewport.get_texture().get_image()
		assert(image != null and not image.is_empty(), "Portrait must render.")
		assert(image.get_pixel(154, 250).a > 0.99, "Belly must remain opaque.")
		assert(image.get_pixel(0, 0).a < 0.01, "Portrait corners must remain transparent.")
		var signature := hash(image.get_data())
		signatures[signature] = true
		if seed_value == 37:
			reference = signature
	assert(signatures.size() == 100, "Every seed must retain a distinct rendered appearance.")
	var material_count := DRAGON._light_maps.size()
	dragon.set_seed(37)
	await process_frame
	await process_frame
	assert(hash(viewport.get_texture().get_image().get_data()) == reference, "Returning to a seed must reproduce the same pixels.")
	var geometry_count := dragon._surface_cache.size()
	# Exercise the animated redraw path: lighting/geometry should not accumulate.
	dragon.animate = true
	dragon.set_process(true)
	for frame in 8:
		await process_frame
	assert(dragon._surface_cache.size() == geometry_count, "Animation must reuse geometry.")
	assert(DRAGON._light_maps.size() == material_count, "Returning to a seed/animation must reuse materials.")
	print("Seeded dragon render test: valid (100 unique portraits, repeatable pixels, stable animation caches)")
	quit()
