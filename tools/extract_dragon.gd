extends SceneTree

const SOURCE := "res://assets/art/dragon_source.png"
const OUTPUT := "res://assets/art/dragon_pink.png"
const BACKGROUND_THRESHOLD := 236
const PADDING := 12


func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	if image.is_empty():
		push_error("Could not load " + SOURCE)
		quit(1)
		return

	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[Vector2i] = []

	for x in width:
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, height - 1))
	for y in height:
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(width - 1, y))

	var head := 0
	while head < queue.size():
		var point := queue[head]
		head += 1
		if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
			continue
		var index := point.y * width + point.x
		if visited[index] == 1:
			continue
		visited[index] = 1

		var color := image.get_pixelv(point)
		if not _is_background(color):
			continue
		image.set_pixelv(point, Color(color.r, color.g, color.b, 0.0))
		queue.append(point + Vector2i.LEFT)
		queue.append(point + Vector2i.RIGHT)
		queue.append(point + Vector2i.UP)
		queue.append(point + Vector2i.DOWN)

	var used := image.get_used_rect()
	used = used.grow(PADDING).intersection(Rect2i(0, 0, width, height))
	var cropped := image.get_region(used)
	var error := cropped.save_png(OUTPUT)
	if error != OK:
		push_error("Could not save extracted dragon: %s" % error)
		quit(1)
		return

	print("Saved %s (%dx%d)" % [OUTPUT, cropped.get_width(), cropped.get_height()])
	quit()


func _is_background(color: Color) -> bool:
	return (
		color.r8 >= BACKGROUND_THRESHOLD
		and color.g8 >= BACKGROUND_THRESHOLD
		and color.b8 >= BACKGROUND_THRESHOLD
	)

