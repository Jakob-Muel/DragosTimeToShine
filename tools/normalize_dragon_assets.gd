extends SceneTree

## Produces presentation-safe derivatives without repainting the dragon artwork.
## Add future opaque-background source images to JOBS and rerun this script.
##
## Run with:
##   Godot --headless --path . --script tools/normalize_dragon_assets.gd

const JOBS := [
	{
		"source": "res://assets/art/ice/ice_dragon_hd.png",
		"output": "res://assets/art/ice/ice_dragon_alpha.png",
	},
]


func _initialize() -> void:
	for job in JOBS:
		_extract_border_background(job.source, job.output)
	print("Normalized ", JOBS.size(), " dragon presentation asset(s)")
	quit()


func _extract_border_background(source_path: String, output_path: String) -> void:
	var image := Image.load_from_file(source_path)
	if image.is_empty():
		printerr("Could not load ", source_path)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)

	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in range(width):
		_queue_background_pixel(image, visited, queue, x, 0)
		_queue_background_pixel(image, visited, queue, x, height - 1)
	for y in range(height):
		_queue_background_pixel(image, visited, queue, 0, y)
		_queue_background_pixel(image, visited, queue, width - 1, y)

	var cursor := 0
	while cursor < queue.size():
		var point := queue[cursor]
		cursor += 1
		image.set_pixel(point.x, point.y, Color(0, 0, 0, 0))
		_queue_background_pixel(image, visited, queue, point.x - 1, point.y)
		_queue_background_pixel(image, visited, queue, point.x + 1, point.y)
		_queue_background_pixel(image, visited, queue, point.x, point.y - 1)
		_queue_background_pixel(image, visited, queue, point.x, point.y + 1)

	# Contract a residual pale fringe without touching enclosed cream details.
	for pass_index in 2:
		var fringe: Array[Vector2i] = []
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				var color := image.get_pixel(x, y)
				if color.a <= 0.0 or not _is_background_color(color, 0.18, 0.62):
					continue
				if _touches_transparency(image, x, y):
					fringe.append(Vector2i(x, y))
		for point in fringe:
			image.set_pixel(point.x, point.y, Color(0, 0, 0, 0))

	var error := image.save_png(output_path)
	if error != OK:
		printerr("Could not save ", output_path, ": ", error)
		quit(1)
		return
	print("Saved ", output_path)


func _queue_background_pixel(
	image: Image,
	visited: PackedByteArray,
	queue: Array[Vector2i],
	x: int,
	y: int
) -> void:
	var width := image.get_width()
	var height := image.get_height()
	if x < 0 or y < 0 or x >= width or y >= height:
		return
	var index := y * width + x
	if visited[index] != 0:
		return
	visited[index] = 1
	if _is_background_color(image.get_pixel(x, y), 0.13, 0.72):
		queue.append(Vector2i(x, y))


func _is_background_color(color: Color, max_saturation: float, min_value: float) -> bool:
	var maximum := maxf(color.r, maxf(color.g, color.b))
	var minimum := minf(color.r, minf(color.g, color.b))
	var saturation := 0.0 if maximum <= 0.0 else (maximum - minimum) / maximum
	return color.a > 0.0 and saturation <= max_saturation and maximum >= min_value


func _touches_transparency(image: Image, x: int, y: int) -> bool:
	return (
		image.get_pixel(x - 1, y).a <= 0.0
		or image.get_pixel(x + 1, y).a <= 0.0
		or image.get_pixel(x, y - 1).a <= 0.0
		or image.get_pixel(x, y + 1).a <= 0.0
	)
