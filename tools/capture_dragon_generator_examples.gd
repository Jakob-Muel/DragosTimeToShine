extends SceneTree

## Four representative portraits rendered by the actual generator.
## Godot --path . --log-file /tmp/dragon-examples.log --script tools/capture_dragon_generator_examples.gd
const DRAGON := preload("res://scripts/ui/seeded_dragon.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const SEEDS := [34, 37, 2, 77]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "res://docs/screenshots/dragon_generator_four_examples.png"
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 660)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.size = viewport.size
	background.color = Color("#e9eeea")
	viewport.add_child(background)
	_label(background, "MEET THE DRAGONS", Vector2(0, 24), Vector2(1600, 48), 30, Color("#514653"))
	for index in SEEDS.size():
		var card := Panel.new()
		card.position = Vector2(24 + index * 394, 92)
		card.size = Vector2(370, 544)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#fffaf0")
		style.set_corner_radius_all(20)
		card.add_theme_stylebox_override("panel", style)
		background.add_child(card)
		var traits: Dictionary = DRAGON.traits_for_seed(SEEDS[index])
		_label(card, traits["palette_name"], Vector2(0, 22), Vector2(370, 30), 18, Color("#8c7880"))
		var dragon := DRAGON.new()
		dragon.animate = false
		dragon.dragon_seed = SEEDS[index]
		dragon.position = Vector2(11, 61)
		dragon.size = Vector2(348, 400)
		card.add_child(dragon)
		_label(card, String(traits["name"]).to_upper(), Vector2(0, 467), Vector2(370, 32), 23, Color("#514653"))
		_label(card, "SEED %03d" % SEEDS[index], Vector2(0, 505), Vector2(370, 24), 15, Color("#9b8b8f"))
	await process_frame
	await process_frame
	var error := viewport.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Could not save dragon examples: %s" % output)
		quit(1)
		return
	print("Saved " + output)
	quit()


func _label(parent: Control, value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", TOKENS.FONT_BOLD)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
