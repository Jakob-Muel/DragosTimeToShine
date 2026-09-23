extends SceneTree

## Renders 25 deterministic dragons at once for visual generator QA.
## Usage: Godot --path . --script tools/capture_dragon_generator_sheet.gd -- 1 /tmp/dragons.png

const SEEDED_DRAGON := preload("res://scripts/ui/seeded_dragon.gd")
const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const COLUMNS := 5
const ROWS := 5
const CELL_SIZE := Vector2i(320, 410)


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var first_seed := maxi(1, int(args[0])) if not args.is_empty() else 1
	var output := args[1] if args.size() > 1 else "/tmp/dragon_generator_sheet.png"
	var viewport := SubViewport.new()
	viewport.size = Vector2i(COLUMNS * CELL_SIZE.x, ROWS * CELL_SIZE.y)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var background := ColorRect.new()
	background.size = viewport.size
	background.color = Color("#dff3ef")
	viewport.add_child(background)

	for index in COLUMNS * ROWS:
		var column := index % COLUMNS
		var row := index / COLUMNS
		var cell_origin := Vector2(column * CELL_SIZE.x, row * CELL_SIZE.y)
		var card := ColorRect.new()
		card.position = cell_origin + Vector2(8, 8)
		card.size = Vector2(CELL_SIZE.x - 16, CELL_SIZE.y - 16)
		card.color = Color("#fffaf0")
		background.add_child(card)

		var seed_value := first_seed + index
		var preview := SEEDED_DRAGON.new() as SeededDragon
		preview.animate = false
		preview.dragon_seed = seed_value
		preview.position = Vector2(8, 26)
		preview.size = Vector2(CELL_SIZE.x - 32, 335)
		card.add_child(preview)

		var traits: Dictionary = SEEDED_DRAGON.traits_for_seed(seed_value)
		var caption := Label.new()
		caption.text = "%03d  %s" % [seed_value, String(traits["name"]).to_upper()]
		caption.position = Vector2(8, 352)
		caption.size = Vector2(CELL_SIZE.x - 32, 32)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_font_override("font", UI_TOKENS.FONT_BOLD)
		caption.add_theme_font_size_override("font_size", 17)
		caption.add_theme_color_override("font_color", Color("#382b3d"))
		card.add_child(caption)

	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	var error := image.save_png(output)
	if error != OK:
		push_error("Could not save generator sheet: %s" % output)
		quit(1)
		return
	print("Saved " + output)
	quit()
