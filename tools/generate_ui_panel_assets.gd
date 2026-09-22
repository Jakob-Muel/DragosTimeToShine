extends SceneTree

## Rebuilds the palette-locked 9-slice panel textures used by WidgetFactory.
## Run with:
##   Godot --headless --path . --script tools/generate_ui_panel_assets.gd

const OUTPUT_DIRECTORY := "res://assets/art/ui_redesign/panels"
const SOURCE_DIRECTORY := OUTPUT_DIRECTORY + "/source"
const ASSET_SIZE := 32
const RUNTIME_SCALE := 3

const VARIANTS := {
	"cream": {
		"outline": Color("#382b3d"),
		"light": Color("#fffaf0"),
		"base": Color("#fff1d2"),
		"dark": Color("#f3d9ae"),
		"shadow": Color("#6f5a70"),
	},
	"cream_pink": {
		"outline": Color("#9e3f68"),
		"light": Color("#fffaf0"),
		"base": Color("#fff1d2"),
		"dark": Color("#f3d9ae"),
		"shadow": Color("#9e3f68"),
	},
	"dark": {
		"outline": Color("#382b3d"),
		"light": Color("#9a78b3"),
		"base": Color("#382b3d"),
		"dark": Color("#6d5085"),
		"shadow": Color("#3d2f2e"),
	},
	"sky": {
		"outline": Color("#382b3d"),
		"light": Color("#dff3ef"),
		"base": Color("#a8e6f5"),
		"dark": Color("#4fb3d0"),
		"shadow": Color("#4fb3d0"),
	},
	"green": {
		"outline": Color("#382b3d"),
		"light": Color("#a9d69a"),
		"base": Color("#a9d69a"),
		"dark": Color("#4f956c"),
		"shadow": Color("#35684d"),
	},
	"gold": {
		"outline": Color("#382b3d"),
		"light": Color("#fff1d2"),
		"base": Color("#f5c877"),
		"dark": Color("#e9aa46"),
		"shadow": Color("#ad6f31"),
	},
	"lilac": {
		"outline": Color("#382b3d"),
		"light": Color("#fff1d2"),
		"base": Color("#9a78b3"),
		"dark": Color("#6d5085"),
		"shadow": Color("#6d5085"),
	},
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE_DIRECTORY))
	for variant_name in VARIANTS:
		var colors: Dictionary = VARIANTS[variant_name]
		_save_panel(variant_name, "raised", colors, true)
		_save_panel(variant_name, "flat", colors, false)
	print("Generated ", VARIANTS.size() * 2, " panel textures in ", OUTPUT_DIRECTORY)
	quit()


func _save_panel(
	variant_name: String,
	state_name: String,
	colors: Dictionary,
	raised: bool
) -> void:
	var image := Image.create(ASSET_SIZE, ASSET_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var face_size := 29 if raised else 32
	if raised:
		_draw_shape(image, 3, 3, face_size, colors.shadow)
	_draw_shape(image, 0, 0, face_size, colors.outline)
	_draw_inner_face(image, face_size, colors)

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


func _draw_inner_face(image: Image, face_size: int, colors: Dictionary) -> void:
	var inner_size := face_size - 2
	for local_y in range(inner_size):
		for local_x in range(inner_size):
			if not _inside_chamfered_rect(local_x, local_y, inner_size, 1):
				continue
			var color: Color = colors.base
			var touches_top := not _inside_chamfered_rect(local_x, local_y - 1, inner_size, 1)
			var touches_left := not _inside_chamfered_rect(local_x - 1, local_y, inner_size, 1)
			var touches_bottom := not _inside_chamfered_rect(local_x, local_y + 1, inner_size, 1)
			var touches_right := not _inside_chamfered_rect(local_x + 1, local_y, inner_size, 1)
			if touches_top or touches_left:
				color = colors.light
			if touches_bottom or touches_right:
				color = colors.dark
			image.set_pixel(local_x + 1, local_y + 1, color)


func _inside_chamfered_rect(x: int, y: int, size: int, chamfer: int) -> bool:
	if x < 0 or y < 0 or x >= size or y >= size:
		return false
	var max_coordinate := size - 1
	return (
		x + y >= chamfer
		and (max_coordinate - x) + y >= chamfer
		and x + (max_coordinate - y) >= chamfer
		and (max_coordinate - x) + (max_coordinate - y) >= chamfer
	)
