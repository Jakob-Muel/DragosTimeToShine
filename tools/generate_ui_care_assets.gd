extends SceneTree

## Produces palette-locked care sprites from the retained ImageGen references.
##
## Run with:
##   Godot --headless --path . --script tools/generate_ui_care_assets.gd

const OUTPUT_ROOT := "res://assets/art/ui_redesign/icons"
const JOBS := [
	{
		"name": "sunberry",
		"source": OUTPUT_ROOT + "/reference/sunberry_reference_source.png",
		"key": "cyan",
		"size": Vector2i(32, 32),
	},
	{
		"name": "grooming_comb",
		"source": OUTPUT_ROOT + "/reference/grooming_comb_reference_source.png",
		"key": "green",
		"size": Vector2i(32, 24),
	},
]
const PALETTE := [
	Color("#382b3d"),
	Color("#6f5a70"),
	Color("#e75d91"),
	Color("#f08bb0"),
	Color("#9e3f68"),
	Color("#fffaf0"),
	Color("#fff1d2"),
	Color("#f3d9ae"),
	Color("#e9aa46"),
	Color("#ad6f31"),
	Color("#a9d69a"),
	Color("#4f956c"),
	Color("#35684d"),
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT + "/source"))
	for job in JOBS:
		_generate_sprite(job)
	print("Generated ", JOBS.size(), " care sprites")
	quit()


func _generate_sprite(job: Dictionary) -> void:
	var image := Image.load_from_file(job.source)
	assert(not image.is_empty(), "Could not load " + String(job.source))
	image.convert(Image.FORMAT_RGBA8)
	_remove_chroma(image, job.key)
	var bounds := image.get_used_rect()
	assert(bounds.size.x > 0 and bounds.size.y > 0, "No subject found in " + String(job.source))
	var subject := image.get_region(bounds)
	var master := _fit_and_quantize(subject, job.size, 2)
	var master_path := "%s/source/%s.png" % [OUTPUT_ROOT, job.name]
	assert(master.save_png(master_path) == OK, "Could not save " + master_path)

	var runtime := master.duplicate()
	runtime.resize(master.get_width() * 3, master.get_height() * 3, Image.INTERPOLATE_NEAREST)
	var runtime_path := "%s/%s.png" % [OUTPUT_ROOT, job.name]
	assert(runtime.save_png(runtime_path) == OK, "Could not save " + runtime_path)
	print("Saved ", runtime_path)


func _remove_chroma(image: Image, key_kind: String) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var is_key := (
				color.g > color.r * 1.3 and color.b > color.r * 1.3 and color.g + color.b > 1.0
				if key_kind == "cyan"
				else color.g > color.r * 1.4 and color.g > color.b * 1.4 and color.g > 0.35
			)
			image.set_pixel(x, y, Color(0, 0, 0, 0) if is_key else Color(color, 1.0))


func _fit_and_quantize(subject: Image, canvas_size: Vector2i, margin: int) -> Image:
	var available := Vector2i(canvas_size.x - margin * 2, canvas_size.y - margin * 2)
	var scale_factor := minf(
		float(available.x) / float(subject.get_width()),
		float(available.y) / float(subject.get_height())
	)
	var fitted_size := Vector2i(
		maxi(1, roundi(subject.get_width() * scale_factor)),
		maxi(1, roundi(subject.get_height() * scale_factor))
	)
	subject.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_NEAREST)
	_quantize(subject)
	var result := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var destination := Vector2i(
		(canvas_size.x - fitted_size.x) / 2,
		(canvas_size.y - fitted_size.y) / 2
	)
	result.blend_rect(subject, Rect2i(Vector2i.ZERO, fitted_size), destination)
	return result


func _quantize(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
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
			image.set_pixel(x, y, Color(nearest, 1.0))
