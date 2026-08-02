extends SceneTree

## Rebuilds the palette-locked cloud textures used by utility and flight screens.
## Run with:
##   Godot --headless --path . --script tools/generate_ui_cloud_assets.gd

const OUTPUT_DIRECTORY := "res://assets/art/ui_redesign/clouds"
const SOURCE_DIRECTORY := OUTPUT_DIRECTORY + "/source"
const RUNTIME_SCALE := 3
const OUTLINE := Color("#6f5a70")
const LIGHT := Color("#fffaf0")
const SHADE := Color("#f3d9ae")

const SHAPES := {
	"large_wide": {
		"size": Vector2i(48, 24),
		"parts": [
			[Rect2i(2, 14, 44, 7), 1], [Rect2i(3, 10, 11, 9), 2],
			[Rect2i(11, 6, 12, 13), 2], [Rect2i(21, 3, 13, 16), 2],
			[Rect2i(32, 9, 12, 10), 2], [Rect2i(42, 12, 4, 6), 1],
		],
		"notches": [[20, 1], [34, 1]],
	},
	"large_tall": {
		"size": Vector2i(48, 24),
		"parts": [
			[Rect2i(2, 14, 44, 7), 1], [Rect2i(5, 10, 13, 10), 2],
			[Rect2i(14, 6, 15, 14), 2], [Rect2i(21, 1, 13, 19), 2],
			[Rect2i(31, 9, 12, 11), 2], [Rect2i(40, 13, 6, 6), 1],
		],
		"notches": [[18, 1], [34, 1]],
	},
	"large_wisp": {
		"size": Vector2i(48, 24),
		"parts": [
			[Rect2i(2, 13, 36, 7), 1], [Rect2i(4, 9, 12, 11), 2],
			[Rect2i(13, 4, 15, 16), 2], [Rect2i(25, 9, 11, 11), 2],
			[Rect2i(34, 14, 8, 5), 1], [Rect2i(40, 11, 6, 6), 1],
		],
	},
	"small_wide": {
		"size": Vector2i(24, 12),
		"parts": [
			[Rect2i(1, 7, 22, 4), 1], [Rect2i(3, 5, 6, 5), 1],
			[Rect2i(7, 3, 7, 7), 1], [Rect2i(13, 5, 7, 5), 1],
		],
	},
	"small_tall": {
		"size": Vector2i(24, 12),
		"parts": [
			[Rect2i(1, 7, 22, 4), 1], [Rect2i(4, 5, 7, 5), 1],
			[Rect2i(8, 1, 8, 9), 1], [Rect2i(15, 5, 6, 5), 1],
		],
	},
	"small_wisp": {
		"size": Vector2i(24, 12),
		"parts": [
			[Rect2i(1, 7, 18, 4), 1], [Rect2i(3, 5, 6, 5), 1],
			[Rect2i(8, 3, 8, 7), 1], [Rect2i(17, 7, 5, 3), 1],
			[Rect2i(20, 5, 3, 3), 1],
		],
	},
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE_DIRECTORY))
	for shape_name in SHAPES:
		_generate_cloud(shape_name, SHAPES[shape_name])
	print("Generated ", SHAPES.size(), " cloud textures in ", OUTPUT_DIRECTORY)
	quit()


func _generate_cloud(shape_name: String, definition: Dictionary) -> void:
	var image_size: Vector2i = definition["size"]
	var mask := _empty_mask(image_size)
	for part in definition["parts"]:
		_stamp_chamfered_rect(mask, image_size, part[0], part[1])
	for notch in definition.get("notches", []):
		_cut_top_notch(mask, image_size, notch[0], notch[1])

	var image := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(image_size.y):
		for x in range(image_size.x):
			if not mask[y][x]:
				continue
			if _is_outline_pixel(mask, image_size, x, y):
				image.set_pixel(x, y, OUTLINE)
			elif _is_shaded_pixel(mask, image_size, x, y):
				image.set_pixel(x, y, SHADE)
			else:
				image.set_pixel(x, y, LIGHT)

	var source_path := "%s/%s.png" % [SOURCE_DIRECTORY, shape_name]
	var error := image.save_png(source_path)
	if error != OK:
		printerr("Could not save ", source_path, ": ", error)
		quit(1)
		return

	var runtime_image := image.duplicate()
	runtime_image.resize(
		image_size.x * RUNTIME_SCALE,
		image_size.y * RUNTIME_SCALE,
		Image.INTERPOLATE_NEAREST
	)
	var runtime_path := "%s/%s.png" % [OUTPUT_DIRECTORY, shape_name]
	error = runtime_image.save_png(runtime_path)
	if error != OK:
		printerr("Could not save ", runtime_path, ": ", error)
		quit(1)


func _empty_mask(image_size: Vector2i) -> Array:
	var mask := []
	for y in range(image_size.y):
		var row := []
		for x in range(image_size.x):
			row.append(false)
		mask.append(row)
	return mask


func _stamp_chamfered_rect(
	mask: Array,
	image_size: Vector2i,
	bounds: Rect2i,
	chamfer: int
) -> void:
	for local_y in range(bounds.size.y):
		for local_x in range(bounds.size.x):
			if not _inside_chamfered_rect(local_x, local_y, bounds.size, chamfer):
				continue
			var x := bounds.position.x + local_x
			var y := bounds.position.y + local_y
			if x >= 0 and y >= 0 and x < image_size.x and y < image_size.y:
				mask[y][x] = true


func _cut_top_notch(mask: Array, image_size: Vector2i, x: int, depth: int) -> void:
	if x < 0 or x >= image_size.x:
		return
	for y in range(image_size.y):
		if not mask[y][x]:
			continue
		for notch_y in range(y, mini(image_size.y, y + depth)):
			mask[notch_y][x] = false
		return


func _inside_chamfered_rect(x: int, y: int, size: Vector2i, chamfer: int) -> bool:
	var max_x := size.x - 1
	var max_y := size.y - 1
	return (
		x + y >= chamfer
		and (max_x - x) + y >= chamfer
		and x + (max_y - y) >= chamfer
		and (max_x - x) + (max_y - y) >= chamfer
	)


func _is_outline_pixel(mask: Array, image_size: Vector2i, x: int, y: int) -> bool:
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			if not _mask_at(mask, image_size, x + offset_x, y + offset_y):
				return true
	return false


func _is_shaded_pixel(mask: Array, image_size: Vector2i, x: int, y: int) -> bool:
	var near_bottom := (
		not _mask_at(mask, image_size, x, y + 1)
		or not _mask_at(mask, image_size, x, y + 2)
	)
	var near_right := (
		not _mask_at(mask, image_size, x + 1, y)
		or not _mask_at(mask, image_size, x + 2, y)
	)
	return near_bottom or (near_right and y > image_size.y * 0.35)


func _mask_at(mask: Array, image_size: Vector2i, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < image_size.x and y < image_size.y and mask[y][x]
