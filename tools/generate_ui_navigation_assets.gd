extends SceneTree

## Draws the palette-locked navigation icons used by the production UI.
## Run with:
##   Godot --headless --path . --script tools/generate_ui_navigation_assets.gd

const OUTPUT_DIRECTORY := "res://assets/art/ui_redesign/icons"
const SOURCE_DIRECTORY := OUTPUT_DIRECTORY + "/source"
const GEAR_SOURCE_SIZE := Vector2i(21, 21)
const RUNTIME_SCALE := 3
const INK := Color("#382b3d")
const STEEL_LIGHT := Color("#c7dce2")
const STEEL := Color("#86a9bd")
const STEEL_DARK := Color("#58758e")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE_DIRECTORY))
	var gear := _draw_gear()

	var source_path := SOURCE_DIRECTORY + "/settings_gear.png"
	assert(gear.save_png(source_path) == OK, "Could not save " + source_path)
	var runtime := gear.duplicate()
	runtime.resize(
		GEAR_SOURCE_SIZE.x * RUNTIME_SCALE,
		GEAR_SOURCE_SIZE.y * RUNTIME_SCALE,
		Image.INTERPOLATE_NEAREST
	)
	var runtime_path := OUTPUT_DIRECTORY + "/settings_gear.png"
	assert(runtime.save_png(runtime_path) == OK, "Could not save " + runtime_path)
	print("Generated settings gear texture in ", OUTPUT_DIRECTORY)
	quit()


func _draw_gear() -> Image:
	var gear := Image.create_empty(
		GEAR_SOURCE_SIZE.x,
		GEAR_SOURCE_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	gear.fill(Color(0, 0, 0, 0))
	var body := PackedByteArray()
	body.resize(GEAR_SOURCE_SIZE.x * GEAR_SOURCE_SIZE.y)
	for y in range(GEAR_SOURCE_SIZE.y):
		for x in range(GEAR_SOURCE_SIZE.x):
			body[_pixel_index(x, y)] = 1 if _is_gear_body(x, y) else 0

	for y in range(GEAR_SOURCE_SIZE.y):
		for x in range(GEAR_SOURCE_SIZE.x):
			if body[_pixel_index(x, y)] == 0:
				continue
			var color := STEEL
			if _touches_exterior(body, x, y):
				color = INK
			elif y >= 14 or x >= 16:
				color = STEEL_DARK
			elif y <= 6 or x <= 5:
				color = STEEL_LIGHT
			gear.set_pixel(x, y, color)

	# A dark inner contour and pale raised rim keep the hole legible at 1x.
	var center := Vector2i(10, 10)
	for y in range(GEAR_SOURCE_SIZE.y):
		for x in range(GEAR_SOURCE_SIZE.x):
			var offset := Vector2i(x, y) - center
			var distance_squared := offset.x * offset.x + offset.y * offset.y
			if distance_squared <= 10:
				gear.set_pixel(x, y, Color(0, 0, 0, 0))
			elif distance_squared <= 18:
				gear.set_pixel(x, y, INK)
			elif distance_squared <= 29 and gear.get_pixel(x, y).a > 0.0:
				gear.set_pixel(x, y, STEEL_LIGHT if y <= center.y else STEEL_DARK)
	return gear


func _is_gear_body(x: int, y: int) -> bool:
	var offset := Vector2i(x - 10, y - 10)
	if offset.x * offset.x + offset.y * offset.y <= 68:
		return true
	# Eight chunky rectangular teeth, with stepped shoulders where they meet the hub.
	if x in range(8, 13) and (y <= 4 or y >= 16):
		return true
	if y in range(8, 13) and (x <= 4 or x >= 16):
		return true
	if x in range(2, 6) and y in range(2, 6):
		return true
	if x in range(15, 19) and y in range(2, 6):
		return true
	if x in range(2, 6) and y in range(15, 19):
		return true
	return x in range(15, 19) and y in range(15, 19)


func _touches_exterior(body: PackedByteArray, x: int, y: int) -> bool:
	for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = Vector2i(x, y) + offset
		if (
			neighbor.x < 0
			or neighbor.y < 0
			or neighbor.x >= GEAR_SOURCE_SIZE.x
			or neighbor.y >= GEAR_SOURCE_SIZE.y
			or body[_pixel_index(neighbor.x, neighbor.y)] == 0
		):
			return true
	return false


func _pixel_index(x: int, y: int) -> int:
	return y * GEAR_SOURCE_SIZE.x + x
