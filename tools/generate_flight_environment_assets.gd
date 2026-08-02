extends SceneTree

## Converts the generated flight-environment reference into palette-locked,
## horizontally seamless 1x masters and 3x runtime textures.
##
## Run with:
##   Godot --headless --path . --script tools/generate_flight_environment_assets.gd

const SOURCE_PATH := "res://assets/art/ui_redesign/reference/flight_forest_reference_source.png"
const OUTPUT_ROOT := "res://assets/art/ui_redesign/flight_environment"
const JOBS := [
	{
		"name": "distant_fields",
		"crop": Rect2i(58, 116, 1578, 180),
		"master_size": Vector2i(240, 30),
	},
	{
		"name": "forest_canopy",
		"crop": Rect2i(58, 360, 1578, 225),
		"master_size": Vector2i(240, 38),
	},
	{
		"name": "meadow_edge",
		"crop": Rect2i(58, 700, 1578, 165),
		"master_size": Vector2i(240, 26),
	},
]
const PALETTE := [
	Color("#382b3d"),
	Color("#6f5a70"),
	Color("#fffaf0"),
	Color("#fff1d2"),
	Color("#f3d9ae"),
	Color("#a8e6f5"),
	Color("#78d6ed"),
	Color("#4fb3d0"),
	Color("#dff3ef"),
	Color("#a9d69a"),
	Color("#4f956c"),
	Color("#35684d"),
]


func _initialize() -> void:
	var source := Image.load_from_file(SOURCE_PATH)
	if source.is_empty():
		push_error("Could not load flight environment reference.")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT + "/source"))
	var generated_layers := {}
	for job in JOBS:
		generated_layers[job.name] = _generate_layer(source, job)
	_generate_coherent_landscape(generated_layers)
	print("Generated ", JOBS.size(), " source layers and one coherent landscape")
	quit()


func _generate_layer(source: Image, job: Dictionary) -> Image:
	var layer := source.get_region(job.crop)
	_remove_chroma_and_quantize(layer)
	layer.resize(job.master_size.x, job.master_size.y, Image.INTERPOLATE_NEAREST)
	var seamless := _mirror_repeat(layer)
	var source_path := "%s/source/%s.png" % [OUTPUT_ROOT, job.name]
	assert(seamless.save_png(source_path) == OK, "Could not save " + source_path)

	var runtime := seamless.duplicate()
	runtime.resize(seamless.get_width() * 3, seamless.get_height() * 3, Image.INTERPOLATE_NEAREST)
	var runtime_path := "%s/%s.png" % [OUTPUT_ROOT, job.name]
	assert(runtime.save_png(runtime_path) == OK, "Could not save " + runtime_path)
	print("Saved ", runtime_path)
	return seamless


func _generate_coherent_landscape(layers: Dictionary) -> void:
	var landscape := Image.create(480, 104, false, Image.FORMAT_RGBA8)
	landscape.fill(Color(0, 0, 0, 0))
	landscape.fill_rect(Rect2i(0, 27, 480, 77), Color("#a9d69a"))

	var distant: Image = layers.distant_fields
	var forest: Image = layers.forest_canopy
	var meadow: Image = layers.meadow_edge
	landscape.blend_rect(distant, Rect2i(Vector2i.ZERO, distant.get_size()), Vector2i(0, 0))
	landscape.blend_rect(forest, Rect2i(Vector2i.ZERO, forest.get_size()), Vector2i(0, 28))

	# Sparse field texture bridges canopy and meadow without introducing another
	# visually separate strip. Mirrored marks preserve the horizontal seam.
	for x in range(13, 240, 31):
		var y := 68 + ((x * 7) % 8)
		_draw_field_mark(landscape, Vector2i(x, y))
		_draw_field_mark(landscape, Vector2i(479 - x, y))

	landscape.blend_rect(meadow, Rect2i(Vector2i.ZERO, meadow.get_size()), Vector2i(0, 78))
	var master_path := OUTPUT_ROOT + "/source/landscape.png"
	assert(landscape.save_png(master_path) == OK, "Could not save " + master_path)
	var runtime := landscape.duplicate()
	runtime.resize(1440, 312, Image.INTERPOLATE_NEAREST)
	var runtime_path := OUTPUT_ROOT + "/landscape.png"
	assert(runtime.save_png(runtime_path) == OK, "Could not save " + runtime_path)
	print("Saved ", runtime_path)


func _draw_field_mark(image: Image, origin: Vector2i) -> void:
	var dark := Color("#4f956c")
	image.set_pixelv(origin, dark)
	image.set_pixelv(origin + Vector2i(0, -1), dark)
	image.set_pixelv(origin + Vector2i(2, 1), dark)
	image.set_pixelv(origin + Vector2i(3, 1), dark)


func _remove_chroma_and_quantize(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if _is_magenta_key(color):
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				image.set_pixel(x, y, Color(_nearest_palette_color(color), 1.0))


func _is_magenta_key(color: Color) -> bool:
	return (
		color.r > 0.62
		and color.b > 0.42
		and color.g < 0.48
		and color.r + color.b > color.g * 2.8
	)


func _nearest_palette_color(color: Color) -> Color:
	var nearest: Color = PALETTE[0]
	var nearest_distance := INF
	for palette_value in PALETTE:
		var candidate: Color = palette_value
		var red_delta: float = color.r - candidate.r
		var green_delta: float = color.g - candidate.g
		var blue_delta: float = color.b - candidate.b
		var distance: float = (
			red_delta * red_delta * 0.2126
			+ green_delta * green_delta * 0.7152
			+ blue_delta * blue_delta * 0.0722
		)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest


func _mirror_repeat(image: Image) -> Image:
	var width := image.get_width()
	var height := image.get_height()
	var result := Image.create(width * 2, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var color := image.get_pixel(x, y)
			result.set_pixel(x, y, color)
			result.set_pixel(width * 2 - 1 - x, y, color)
	return result
