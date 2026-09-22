extends SceneTree

## Rasterize editable SVG sources with Godot's own SVG renderer.
func _init() -> void:
	var files: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/comic/manifest.json"))
	for relative: String in files:
		var source := "res://assets/art/comic/source/" + relative.get_basename() + ".svg"
		var output := "res://assets/art/comic/" + relative
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(source), 2.0)
		if error != OK:
			push_error("Cannot render " + source)
			quit(1)
			return
		image.resize(image.get_width() / 2, image.get_height() / 2, Image.INTERPOLATE_LANCZOS)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
		assert(image.save_png(output) == OK)
	print("Rendered ", files.size(), " comic assets")
	quit()
