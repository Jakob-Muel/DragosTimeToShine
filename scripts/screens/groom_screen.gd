extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const DRAGON_TEXTURE := preload("res://assets/art/dragon_pink_hd.png")
const ICE_DRAGON_TEXTURE := preload("res://assets/art/ice/ice_dragon_hd.png")
const GROOM_CLEAN_PER_PIXEL := 0.008

const PINK := UiTokens.PINK
const PINK_DARK := UiTokens.PINK_DARK
const CREAM := UiTokens.CREAM
const MINT := UiTokens.MINT
const INK := UiTokens.INK
const INK_SOFT := UiTokens.INK_SOFT
const WHITE := UiTokens.WHITE
const GOLD := UiTokens.GOLD
const SKY := UiTokens.SKY
const FONT_BOLD := UiTokens.FONT_BOLD

var selected_dragon_id := "luma"
var active_dragon_texture: Texture2D = DRAGON_TEXTURE
var groom_area: Control
var groom_sprite: TextureRect
var groom_comb: Control
var groom_complete_label: Label
var clean_bar: ProgressBar
var clean_label: Label
var dragon_alpha_image: Image
var groom_stretch_target := Vector2.ONE
var groom_rotation_target := 0.0
var groom_drag_accumulator := Vector2.ZERO
var groom_completion_started := false
var groom_completion_tween: Tween
var grooming := false
var random := RandomNumberGenerator.new()

var cleanliness: float:
	get:
		return GameState.get_dragon_cleanliness(selected_dragon_id)
	set(value):
		GameState.set_dragon_cleanliness(selected_dragon_id, value)


func _process(delta: float) -> void:
	if not is_instance_valid(groom_sprite):
		return
	var response_speed := 13.0 if grooming else 7.5
	var response: float = 1.0 - exp(-response_speed * delta)
	var desired_scale := groom_stretch_target if grooming else Vector2.ONE
	var desired_rotation := groom_rotation_target if grooming else 0.0
	groom_sprite.scale = groom_sprite.scale.lerp(desired_scale, response)
	groom_sprite.rotation = lerpf(groom_sprite.rotation, desired_rotation, response)
	if not grooming:
		groom_stretch_target = groom_stretch_target.lerp(Vector2.ONE, response)
		groom_rotation_target = lerpf(groom_rotation_target, 0.0, response)


func selected_dragon_data() -> Dictionary:
	return GameState.get_dragon(selected_dragon_id)


func selected_dragon_name() -> String:
	return tr_text(GameState.dragon_name_key(selected_dragon_data()))


func dragon_texture_for(dragon_data: Dictionary) -> Texture2D:
	var texture := GameState.dragon_texture(dragon_data)
	if texture != null:
		return texture
	return ICE_DRAGON_TEXTURE if GameState.dragon_has_type(dragon_data, &"ice") else DRAGON_TEXTURE


func _go_habitat() -> void:
	navigate("habitat", {"selected_dragon_id": selected_dragon_id})

func build() -> void:
	selected_dragon_id = String(context.get("selected_dragon_id", "luma"))
	random.randomize()
	var top_shift := safe_top_y(32.0) - 32.0
	var dragon_data := selected_dragon_data()
	var uses_pixel_filter := not GameState.dragon_has_type(dragon_data, &"sunwing")
	var accent := _dragon_accent_color(dragon_data)
	active_dragon_texture = dragon_texture_for(dragon_data)
	dragon_alpha_image = active_dragon_texture.get_image()
	var height_mix := clampf((canvas_size.y - 1280.0) / (GameCanvas.BASE_DESIGN_HEIGHT - 1280.0), 0.0, 1.0)
	var portrait_height := lerpf(560.0, 738.0, height_mix)
	var sprite_height := portrait_height - 88.0
	var portrait_bottom := 398.0 + top_shift + portrait_height
	var hint_y := portrait_bottom + 20.0
	var complete_y := hint_y + 80.0
	var done_y := canvas_size.y - 142.0

	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	add_child(sky)
	var wash := ColorRect.new()
	wash.position = Vector2.ZERO
	wash.size = canvas_size
	wash.color = _dragon_wash_color(dragon_data)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, 32 + top_shift)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override("panel", WidgetFactory.panel_style(Color(1, 0.98, 0.91, 0.97), INK, 18, 6))
	add_child(top_panel)
	var back := WidgetFactory.small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_leave_grooming)
	top_panel.add_child(back)
	var active_dragon_name := selected_dragon_name()
	var title := WidgetFactory.label(tr_text("GROOM_TITLE_DYNAMIC", {"name": active_dragon_name}), 40, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(98, 14)
	title.size = Vector2(474, 70)
	top_panel.add_child(title)

	var progress_panel := Panel.new()
	progress_panel.position = Vector2(40, 164 + top_shift)
	progress_panel.size = Vector2(640, 118)
	progress_panel.z_index = 100
	progress_panel.add_theme_stylebox_override("panel", WidgetFactory.panel_style(WHITE, INK, 16, 5))
	add_child(progress_panel)
	var clean_title := WidgetFactory.label(tr_text("CLEAN"), 25, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	clean_title.position = Vector2(22, 14)
	clean_title.size = Vector2(180, 34)
	progress_panel.add_child(clean_title)
	clean_label = WidgetFactory.label("%d%%" % floori(cleanliness), 25, accent, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	clean_label.position = Vector2(490, 14)
	clean_label.size = Vector2(120, 34)
	progress_panel.add_child(clean_label)
	clean_bar = ProgressBar.new()
	clean_bar.position = Vector2(22, 60)
	clean_bar.size = Vector2(596, 34)
	clean_bar.value = cleanliness
	clean_bar.show_percentage = false
	clean_bar.add_theme_stylebox_override("background", WidgetFactory.panel_style(Color("#e3d4b8"), INK, 8, 0))
	clean_bar.add_theme_stylebox_override("fill", WidgetFactory.panel_style(MINT, INK, 8, 0))
	progress_panel.add_child(clean_bar)

	var instruction := Panel.new()
	instruction.position = Vector2(82, 306 + top_shift)
	instruction.size = Vector2(556, 66)
	instruction.z_index = 100
	instruction.add_theme_stylebox_override("panel", WidgetFactory.panel_style(Color(0.19, 0.13, 0.25, 0.92), INK, 12, 3))
	add_child(instruction)
	var instruction_text := WidgetFactory.label(
		tr_text("GROOM_INSTRUCTION_DYNAMIC", {"name": active_dragon_name}),
		24,
		WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	instruction_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	instruction.add_child(instruction_text)

	var portrait_panel := Panel.new()
	portrait_panel.position = Vector2(40, 398 + top_shift)
	portrait_panel.size = Vector2(640, portrait_height)
	portrait_panel.clip_contents = true
	portrait_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(_dragon_portrait_color(dragon_data), INK, 22, 7)
	)
	add_child(portrait_panel)

	groom_sprite = WidgetFactory.texture_rect(active_dragon_texture, Rect2(90, 420 + top_shift, 540, sprite_height), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	groom_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if uses_pixel_filter else CanvasItem.TEXTURE_FILTER_LINEAR
	groom_sprite.pivot_offset = groom_sprite.size / 2.0
	groom_sprite.z_index = 20
	add_child(groom_sprite)

	groom_area = Control.new()
	groom_area.position = portrait_panel.position
	groom_area.size = portrait_panel.size
	groom_area.clip_contents = true
	groom_area.mouse_filter = Control.MOUSE_FILTER_STOP
	groom_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	groom_area.z_index = 30
	groom_area.gui_input.connect(_on_groom_input)
	add_child(groom_area)

	groom_comb = PIXEL_ART.PixelComb.new()
	groom_comb.position = Vector2(groom_area.size.x - 112.0, groom_area.size.y - 104.0)
	groom_comb.size = Vector2(96, 80)
	groom_comb.z_index = 1
	groom_area.add_child(groom_comb)

	var hint := WidgetFactory.label(tr_text("GROOM_HINT"), 22, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	hint.position = Vector2(55, hint_y)
	hint.size = Vector2(610, 74)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)

	groom_complete_label = WidgetFactory.label(tr_text("SPARKLING_CLEAN"), 28, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	groom_complete_label.position = Vector2(80, complete_y)
	groom_complete_label.size = Vector2(560, 54)
	groom_complete_label.visible = cleanliness >= 100
	groom_complete_label.add_theme_color_override("font_outline_color", WHITE)
	groom_complete_label.add_theme_constant_override("outline_size", 5)
	add_child(groom_complete_label)

	var done := WidgetFactory.button(tr_text("GROOM_DONE"), Rect2(120, done_y, 480, 106), PINK, PINK_DARK)
	done.z_index = 100
	done.pressed.connect(_leave_grooming)
	add_child(done)


func _dragon_accent_color(dragon: Dictionary) -> Color:
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"earth"):
		return Color("#d9571f")
	if GameState.dragon_has_type(dragon, &"earth") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#607d69")
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#824ca0")
	if GameState.dragon_has_type(dragon, &"fire"):
		return Color("#d8492f")
	if GameState.dragon_has_type(dragon, &"water"):
		return Color("#168ec8")
	if GameState.dragon_has_type(dragon, &"earth"):
		return Color("#8b633d")
	if GameState.dragon_has_type(dragon, &"ice"):
		return Color("#3187b8")
	return PINK_DARK


func _dragon_wash_color(dragon: Dictionary) -> Color:
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"earth"):
		return Color(1.0, 0.36, 0.12, 0.25)
	if GameState.dragon_has_type(dragon, &"earth") and GameState.dragon_has_type(dragon, &"water"):
		return Color(0.42, 0.58, 0.48, 0.24)
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"water"):
		return Color(0.73, 0.50, 0.83, 0.23)
	if GameState.dragon_has_type(dragon, &"fire"):
		return Color(1.0, 0.58, 0.25, 0.25)
	if GameState.dragon_has_type(dragon, &"water"):
		return Color(0.35, 0.92, 0.95, 0.25)
	if GameState.dragon_has_type(dragon, &"earth"):
		return Color(0.73, 0.52, 0.27, 0.24)
	if GameState.dragon_has_type(dragon, &"ice"):
		return Color(0.66, 0.91, 1.0, 0.27)
	return Color(1.0, 0.72, 0.84, 0.23)


func _dragon_portrait_color(dragon: Dictionary) -> Color:
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"earth"):
		return Color("#ffe0bd")
	if GameState.dragon_has_type(dragon, &"earth") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#e7e3c4")
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#fff0cf")
	if GameState.dragon_has_type(dragon, &"fire"):
		return Color("#ffe0bd")
	if GameState.dragon_has_type(dragon, &"water"):
		return Color("#d6f7f4")
	if GameState.dragon_has_type(dragon, &"earth"):
		return Color("#f0ddac")
	if GameState.dragon_has_type(dragon, &"ice"):
		return Color("#dff8ff")
	return Color("#bdeaf7")


func _on_groom_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			grooming = true
			groom_drag_accumulator = Vector2.ZERO
			groom_stretch_target = Vector2.ONE
			_groom_at(event.position, Vector2.ZERO)
		else:
			_finish_groom_stretch()
	elif event is InputEventScreenDrag and grooming:
		_groom_at(event.position, event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			grooming = true
			groom_drag_accumulator = Vector2.ZERO
			groom_stretch_target = Vector2.ONE
			_groom_at(event.position, Vector2.ZERO)
		else:
			_finish_groom_stretch()
	elif event is InputEventMouseMotion and grooming:
		_groom_at(event.position, event.relative)

func _groom_at(local_position: Vector2, drag_delta: Vector2) -> void:
	if not is_instance_valid(groom_sprite):
		return
	var half_comb := groom_comb.size / 2.0
	var clamped_pointer := local_position.clamp(half_comb, groom_area.size - half_comb)
	groom_comb.position = clamped_pointer - half_comb
	if drag_delta.length_squared() > 0.1:
		if not _is_over_dragon(local_position):
			groom_drag_accumulator *= 0.72
			groom_stretch_target = Vector2.ONE
			groom_rotation_target = 0.0
			return
		var previous_cleanliness := cleanliness
		cleanliness = minf(100.0, cleanliness + drag_delta.length() * GROOM_CLEAN_PER_PIXEL)
		if floori(cleanliness) != floori(previous_cleanliness):
			_update_clean_display()
			_spawn_groom_sparkle(groom_area.position + local_position)
		_update_continuous_stretch(drag_delta)
		if previous_cleanliness < 100.0 and cleanliness >= 100.0:
			_complete_grooming()

func _is_over_dragon(local_position: Vector2) -> bool:
	if dragon_alpha_image == null or not is_instance_valid(groom_area):
		return false
	var texture_size := Vector2(active_dragon_texture.get_width(), active_dragon_texture.get_height())
	var sprite_local_position := groom_area.position + local_position - groom_sprite.position
	var display_scale: float = minf(groom_sprite.size.x / texture_size.x, groom_sprite.size.y / texture_size.y)
	var displayed_size := texture_size * display_scale
	var display_offset := (groom_sprite.size - displayed_size) * 0.5
	var image_position := (sprite_local_position - display_offset) / display_scale
	if image_position.x < 0.0 or image_position.y < 0.0:
		return false
	if image_position.x >= texture_size.x or image_position.y >= texture_size.y:
		return false
	return dragon_alpha_image.get_pixelv(Vector2i(image_position)).a > 0.15

func _update_continuous_stretch(drag_delta: Vector2) -> void:
	# Accumulate recent motion so deformation flows continuously with the stroke
	# instead of restarting an elastic animation for every input event.
	groom_drag_accumulator = (groom_drag_accumulator * 0.82 + drag_delta * 4.0).limit_length(95.0)
	var horizontal_strength := absf(groom_drag_accumulator.x) / 95.0
	var vertical_strength := absf(groom_drag_accumulator.y) / 95.0
	groom_stretch_target = Vector2(
		1.0 + horizontal_strength * 0.14 - vertical_strength * 0.04,
		1.0 + vertical_strength * 0.16 - horizontal_strength * 0.04
	)
	groom_rotation_target = clampf(groom_drag_accumulator.x / 2400.0, -0.035, 0.035)

func _finish_groom_stretch() -> void:
	grooming = false
	groom_stretch_target = Vector2.ONE
	groom_rotation_target = 0.0
	groom_drag_accumulator = Vector2.ZERO

func _update_clean_display() -> void:
	if is_instance_valid(clean_bar):
		clean_bar.value = cleanliness
	if is_instance_valid(clean_label):
		clean_label.text = "%d%%" % floori(cleanliness)
	if is_instance_valid(groom_complete_label):
		groom_complete_label.visible = cleanliness >= 100

func _complete_grooming() -> void:
	if groom_completion_started:
		return
	groom_completion_started = true
	_finish_groom_stretch()
	GameState.save_game()
	_update_clean_display()
	var celebration_origin := Vector2(
		canvas_size.x * 0.5,
		groom_area.position.y + groom_area.size.y * 0.34
	)
	_burst_confetti(self, celebration_origin, 46, 3900)
	groom_completion_tween = create_tween()
	groom_completion_tween.tween_interval(1.55)
	groom_completion_tween.tween_callback(_finish_grooming)

func _finish_grooming() -> void:
	call_deferred("_go_habitat")

func _leave_grooming() -> void:
	GameState.save_game()
	_go_habitat()

func _spawn_groom_sparkle(at_position: Vector2) -> void:
	var sparkle := WidgetFactory.label("✦", 27, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	sparkle.position = at_position - Vector2(20, 20)
	sparkle.size = Vector2(40, 40)
	sparkle.z_index = 60
	sparkle.add_theme_color_override("font_outline_color", PINK_DARK)
	sparkle.add_theme_constant_override("outline_size", 4)
	add_child(sparkle)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sparkle, "position:y", sparkle.position.y - 34.0, 0.45)
	tween.tween_property(sparkle, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(sparkle.queue_free)

func debug_groom_stroke() -> void:
	grooming = true
	groom_drag_accumulator = Vector2.ZERO
	for index in 480:
		var column := index % 8
		var row := (index / 8) % 6
		var point := groom_sprite.position - groom_area.position + Vector2(
			groom_sprite.size.x * (0.20 + column * 0.085),
			groom_sprite.size.y * (0.28 + row * 0.085)
		)
		_groom_at(point, Vector2(58, 12))
		if cleanliness >= 100.0:
			break


func debug_groom_off_sprite() -> void:
	grooming = true
	var clean_before := cleanliness
	_groom_at(Vector2(groom_area.size.x - 12.0, 32.0), Vector2(54, 0))
	assert(cleanliness == clean_before, "Off-sprite grooming must not increase Clean.")


func _burst_confetti(parent: Control, origin: Vector2, piece_count: int, layer: int) -> void:
	var colors := [PINK, GOLD, MINT, SKY, Color("#9b7ede"), CREAM]
	for piece_index in piece_count:
		var piece := PIXEL_ART.ConfettiPiece.new()
		piece.position = origin + Vector2(random.randf_range(-18.0, 18.0), random.randf_range(-8.0, 8.0))
		piece.size = Vector2(random.randi_range(10, 17), random.randi_range(16, 27))
		piece.velocity = Vector2(random.randf_range(-330.0, 330.0), random.randf_range(-570.0, -280.0))
		piece.spin = random.randf_range(-9.0, 9.0)
		piece.piece_color = colors[piece_index % colors.size()]
		piece.z_index = layer
		parent.add_child(piece)
