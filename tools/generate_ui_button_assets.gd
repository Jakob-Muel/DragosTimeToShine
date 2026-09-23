extends SceneTree

## Rebuilds the exact, palette-locked 9-slice button textures used by WidgetFactory.
## Run with:
##   Godot --headless --path . --script tools/generate_ui_button_assets.gd

const OUTPUT_DIRECTORY := "res://assets/art/ui_redesign/buttons"
const SOURCE_DIRECTORY := OUTPUT_DIRECTORY + "/source"
const ASSET_SIZE := 32
const RUNTIME_SCALE := 3
const INK := Color("#382b3d")

const VARIANTS := {
	"pink": {
		"light": Color("#f08bb0"),
		"base": Color("#e75d91"),
		"dark": Color("#9e3f68"),
	},
	"green": {
		"light": Color("#a9d69a"),
		"base": Color("#4f956c"),
		"dark": Color("#35684d"),
	},
	"gold": {
		"light": Color("#f5c877"),
		"base": Color("#e9aa46"),
		"dark": Color("#ad6f31"),
	},
	"cream": {
		"light": Color("#fffaf0"),
		"base": Color("#f3d9ae"),
		"dark": Color("#d9b98a"),
	},
	"lilac": {
		"light": Color("#fff1d2"),
		"base": Color("#9a78b3"),
		"dark": Color("#6d5085"),
	},
	"sky": {
		"light": Color("#a8e6f5"),
		"base": Color("#78d6ed"),
		"dark": Color("#4fb3d0"),
	},
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE_DIRECTORY))
	for variant_name in VARIANTS:
		var colors: Dictionary = VARIANTS[variant_name]
		_save_button(variant_name, "idle", colors, false)
		_save_button(variant_name, "pressed", colors, true)
	print("Generated ", VARIANTS.size() * 2, " button textures in ", OUTPUT_DIRECTORY)
	quit()


func _save_button(
	variant_name: String,
	state_name: String,
	colors: Dictionary,
	pressed: bool
) -> void:
	var image := Image.create(ASSET_SIZE, ASSET_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var face_size := 31 if pressed else 29
	var shadow_offset := 1 if pressed else 3
	_draw_shape(image, shadow_offset, shadow_offset, face_size, colors.dark)
	_draw_shape(image, 0, 0, face_size, INK)
	_draw_inner_face(image, face_size, colors, pressed)

	var file_name := "%s_%s.png" % [variant_name, state_name]
	var source_path := "%s/%s" % [SOURCE_DIRECTORY, file_name]
	var error := image.save_png(source_path)
	if error != OK:
		printerr("Could not save ", source_path, ": ", error)
		quit(1)
		return

	var runtime_image := image.duplicate()
	runtime_image.resize(
		ASSET_SIZE * RUNTIME_SCALE,
		ASSET_SIZE * RUNTIME_SCALE,
		Image.INTERPOLATE_NEAREST
	)
	var runtime_path := "%s/%s" % [OUTPUT_DIRECTORY, file_name]
	error = runtime_image.save_png(runtime_path)
	if error != OK:
		printerr("Could not save ", runtime_path, ": ", error)
		quit(1)


func _draw_shape(image: Image, offset_x: int, offset_y: int, size: int, color: Color) -> void:
	for local_y in range(size):
		for local_x in range(size):
			if _inside_chamfered_rect(local_x, local_y, size, 2):
				image.set_pixel(offset_x + local_x, offset_y + local_y, color)


func _draw_inner_face(image: Image, face_size: int, colors: Dictionary, pressed: bool) -> void:
	var inner_size := face_size - 2
	var fill_color: Color = colors.dark if pressed else colors.base
	var top_left_color: Color = colors.dark if pressed else colors.light
	var bottom_right_color: Color = colors.light if pressed else colors.dark

	for local_y in range(inner_size):
		for local_x in range(inner_size):
			if not _inside_chamfered_rect(local_x, local_y, inner_size, 1):
				continue
			var color := fill_color
			var touches_top := not _inside_chamfered_rect(local_x, local_y - 1, inner_size, 1)
			var touches_left := not _inside_chamfered_rect(local_x - 1, local_y, inner_size, 1)
			var touches_bottom := not _inside_chamfered_rect(local_x, local_y + 1, inner_size, 1)
			var touches_right := not _inside_chamfered_rect(local_x + 1, local_y, inner_size, 1)
			if touches_top or touches_left:
				color = top_left_color
			if touches_bottom or touches_right:
				color = bottom_right_color
			image.set_pixel(local_x + 1, local_y + 1, color)


func _inside_chamfered_rect(x: int, y: int, size: int, chamfer: int) -> bool:
	if x < 0 or y < 0 or x >= size or y >= size:
		return false
	var max_coordinate := size - 1
	var top_left_distance := x + y
	var top_right_distance := (max_coordinate - x) + y
	var bottom_left_distance := x + (max_coordinate - y)
	var bottom_right_distance := (max_coordinate - x) + (max_coordinate - y)
	return (
		top_left_distance >= chamfer
		and top_right_distance >= chamfer
		and bottom_left_distance >= chamfer
		and bottom_right_distance >= chamfer
	)
