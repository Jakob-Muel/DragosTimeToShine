extends SceneTree

const DRAGON_SOURCE := "res://assets/art/ice/ice_dragon_source.png"
const DRAGON_OUTPUT := "res://assets/art/ice/ice_dragon_hd.png"
const EGG_SOURCE := "res://assets/art/ice/ice_egg_alpha.png"
const EGG_OUTPUT := "res://assets/art/ice/ice_egg.png"
const PADDING := 16


func _init() -> void:
	var dragon := Image.load_from_file(DRAGON_SOURCE)
	if dragon.is_empty():
		push_error("Could not load " + DRAGON_SOURCE)
		quit(1)
		return
	dragon.convert(Image.FORMAT_RGBA8)
	_remove_light_border_background(dragon)
	if not _crop_resize_and_save(dragon, DRAGON_OUTPUT, 1200):
		quit(1)
		return

	var egg := Image.load_from_file(EGG_SOURCE)
	if egg.is_empty():
		push_error("Could not load " + EGG_SOURCE)
		quit(1)
		return
	egg.convert(Image.FORMAT_RGBA8)
	if not _crop_resize_and_save(egg, EGG_OUTPUT, 420):
		quit(1)
		return

	print("Prepared ice-dragon assets.")
	quit()


func _remove_light_border_background(image: Image) -> void:
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
		if color.r8 < 232 or color.g8 < 232 or color.b8 < 232:
			continue
		image.set_pixelv(point, Color(color.r, color.g, color.b, 0.0))
		queue.append(point + Vector2i.LEFT)
		queue.append(point + Vector2i.RIGHT)
		queue.append(point + Vector2i.UP)
		queue.append(point + Vector2i.DOWN)


func _crop_resize_and_save(image: Image, path: String, target_width: int) -> bool:
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		push_error("No visible pixels found for " + path)
		return false
	used = used.grow(PADDING).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var cropped := image.get_region(used)
	var target_height := maxi(1, roundi(float(cropped.get_height()) * target_width / cropped.get_width()))
	cropped.resize(target_width, target_height, Image.INTERPOLATE_NEAREST)
	var error := cropped.save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error])
		return false
	print("Saved %s (%dx%d)" % [path, target_width, target_height])
	return true
