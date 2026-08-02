extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")

var egg_id := ""
var query_steps := true
var step_error_message := ""
var random := RandomNumberGenerator.new()


func build() -> void:
	random.randomize()
	egg_id = String(context.get("egg_id", ""))
	query_steps = bool(context.get("query_steps", true))
	if not StepCounter.steps_ready.is_connected(_on_steps_ready):
		StepCounter.steps_ready.connect(_on_steps_ready)
	if not StepCounter.permission_changed.is_connected(_on_permission_changed):
		StepCounter.permission_changed.connect(_on_permission_changed)
	if not StepCounter.step_error.is_connected(_on_step_error):
		StepCounter.step_error.connect(_on_step_error)
	_build_content()


func _exit_tree() -> void:
	if StepCounter.steps_ready.is_connected(_on_steps_ready):
		StepCounter.steps_ready.disconnect(_on_steps_ready)
	if StepCounter.permission_changed.is_connected(_on_permission_changed):
		StepCounter.permission_changed.disconnect(_on_permission_changed)
	if StepCounter.step_error.is_connected(_on_step_error):
		StepCounter.step_error.disconnect(_on_step_error)


func _build_content() -> void:
	var egg := GameState.get_egg(egg_id)
	if egg.is_empty():
		call_deferred("navigate", "eggs", {})
		return
	var top_shift := safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)
	var back := WidgetFactory.small_button("‹", Rect2(32, 44 + top_shift, 78, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("eggs", {}))
	add_child(back)
	var title := WidgetFactory.label(
		tr_text("EGG_DETAIL_TITLE"), 43, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	add_child(title)

	var egg_panel := Panel.new()
	egg_panel.position = Vector2(70, 170 + top_shift)
	egg_panel.size = Vector2(580, 620)
	egg_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 24, 9)
	)
	add_child(egg_panel)
	_add_egg_art(egg_panel, egg, Rect2(165, 35, 250, 330))
	var egg_name := WidgetFactory.label(
		tr_text(GameState.egg_name_key(egg)),
		38,
		_egg_accent_color(egg),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	egg_name.position = Vector2(30, 372)
	egg_name.size = Vector2(520, 55)
	egg_panel.add_child(egg_name)

	var progress := int(egg.get("progress_steps", 0))
	var required := int(egg.get("required_steps", GameState.EGG_REQUIRED_STEPS))
	var progress_label := WidgetFactory.label(
		tr_text("EGG_STEP_PROGRESS", {"current": progress, "required": required}),
		25,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	progress_label.position = Vector2(30, 438)
	progress_label.size = Vector2(520, 42)
	egg_panel.add_child(progress_label)
	var progress_bar := ProgressBar.new()
	progress_bar.position = Vector2(45, 496)
	progress_bar.size = Vector2(490, 38)
	progress_bar.max_value = required
	progress_bar.value = progress
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override(
		"background",
		WidgetFactory.panel_style(Color("#e3d4b8"), UiTokens.INK, 8, 0)
	)
	progress_bar.add_theme_stylebox_override(
		"fill",
		WidgetFactory.panel_style(UiTokens.GOLD, UiTokens.INK, 8, 0)
	)
	egg_panel.add_child(progress_bar)
	var provider := WidgetFactory.label(
		tr_text("STEP_PROVIDER", {
			"provider": tr_text("STEP_PROVIDER_%s" % StepCounter.provider_name().to_upper()),
		}),
		19,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	provider.position = Vector2(30, 548)
	provider.size = Vector2(520, 32)
	egg_panel.add_child(provider)
	if not step_error_message.is_empty():
		var error_label := WidgetFactory.label(
			_step_error_text(step_error_message),
			17,
			UiTokens.PINK_DARK,
			HORIZONTAL_ALIGNMENT_CENTER,
			UiTokens.FONT_BOLD
		)
		error_label.position = Vector2(80, 786 + top_shift)
		error_label.size = Vector2(560, 68)
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(error_label)

	var action_y := 860.0 if not step_error_message.is_empty() else 840.0
	var incubation_start := int(egg.get("incubation_start", 0))
	if incubation_start == 0:
		var start := WidgetFactory.button(
			tr_text("START_HATCHING"),
			Rect2(110, action_y + top_shift, 500, 110),
			UiTokens.PINK,
			UiTokens.PINK_DARK
		)
		start.pressed.connect(start_incubation)
		add_child(start)
	elif GameState.can_hatch(egg_id):
		var hatch_button := WidgetFactory.button(
			tr_text("HATCH_NOW"),
			Rect2(110, action_y + top_shift, 500, 110),
			UiTokens.PINK,
			UiTokens.PINK_DARK
		)
		hatch_button.pressed.connect(hatch)
		add_child(hatch_button)
	elif StepCounter.is_mock():
		var test_steps := WidgetFactory.button(
			tr_text("ADD_TEST_STEPS"),
			Rect2(110, action_y + top_shift, 500, 110),
			Color("#8ed5aa"),
			Color("#4d9a70")
		)
		test_steps.pressed.connect(add_test_steps)
		add_child(test_steps)
	elif not StepCounter.has_permission():
		var permission := WidgetFactory.button(
			tr_text("STEP_PERMISSION"),
			Rect2(110, action_y + top_shift, 500, 110),
			UiTokens.PINK,
			UiTokens.PINK_DARK
		)
		permission.pressed.connect(StepCounter.request_permission)
		add_child(permission)
	else:
		var refresh := WidgetFactory.button(
			tr_text("REFRESH_STEPS"),
			Rect2(110, action_y + top_shift, 500, 110),
			Color("#8ed5aa"),
			Color("#4d9a70")
		)
		refresh.pressed.connect(refresh_steps)
		add_child(refresh)

	if query_steps and incubation_start > 0 and (StepCounter.is_mock() or StepCounter.has_permission()):
		call_deferred("refresh_steps")


func start_incubation() -> void:
	GameState.start_incubation(egg_id, StepCounter.get_mock_total_steps())
	if not StepCounter.is_mock() and not StepCounter.has_permission():
		StepCounter.request_permission()
	_rebuild()


func refresh_steps() -> void:
	var egg := GameState.get_egg(egg_id)
	if egg.is_empty() or int(egg.get("incubation_start", 0)) == 0:
		return
	step_error_message = ""
	StepCounter.query_steps_since(
		int(egg.get("incubation_start", 0)),
		int(egg.get("mock_baseline", 0))
	)


func add_test_steps() -> void:
	StepCounter.add_mock_steps(250)
	refresh_steps()


func hatch() -> void:
	var egg := GameState.get_egg(egg_id)
	var hatch_message_key := GameState.egg_hatch_message_key(egg)
	var accent := _egg_accent_color(egg)
	if not GameState.hatch_egg(egg_id):
		return
	var message := WidgetFactory.label(
		tr_text(hatch_message_key),
		48,
		accent,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	message.position = Vector2(45, canvas_size.y * 0.5 - 70)
	message.size = Vector2(630, 100)
	message.z_index = 3950
	message.add_theme_color_override("font_outline_color", UiTokens.WHITE)
	message.add_theme_constant_override("outline_size", 8)
	add_child(message)
	_burst_confetti(Vector2(canvas_size.x * 0.5, canvas_size.y * 0.48), 54, 3900)
	var hatch_tween := create_tween()
	hatch_tween.tween_interval(1.55)
	hatch_tween.tween_callback(navigate.bind("dragons", {}))


func _on_steps_ready(start_unix: int, steps: int) -> void:
	var egg := GameState.get_egg(egg_id)
	if egg.is_empty() or int(egg.get("incubation_start", 0)) != start_unix:
		return
	GameState.update_egg_progress(egg_id, steps)
	_rebuild(false)


func _on_permission_changed(granted: bool) -> void:
	if granted:
		refresh_steps()


func _on_step_error(message: String) -> void:
	push_warning("Step counter: %s" % message)
	step_error_message = message
	_rebuild(false)


func _rebuild(should_query := true) -> void:
	navigate("egg_detail", {"egg_id": egg_id, "query_steps": should_query})


func _step_error_text(message: String) -> String:
	if "entitlement" in message.to_lower():
		return tr_text("STEP_ERROR_ENTITLEMENT")
	return tr_text("STEP_ERROR_WITH_DETAIL", {"detail": message})


func _add_egg_art(parent: Control, egg: Dictionary, rect: Rect2) -> void:
	var texture := GameState.egg_texture(egg)
	if texture != null:
		var egg_art := WidgetFactory.texture_rect(
			texture,
			rect,
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		egg_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(egg_art)
		return
	var sunwing_egg := PIXEL_ART.PixelEgg.new()
	sunwing_egg.position = rect.position
	sunwing_egg.size = rect.size
	parent.add_child(sunwing_egg)


func _egg_accent_color(egg: Dictionary) -> Color:
	var definition := GameState.egg_definition(egg)
	if definition != null:
		if definition.has_type(&"fire") and definition.has_type(&"earth"):
			return Color("#d9571f")
		if definition.has_type(&"earth") and definition.has_type(&"water"):
			return Color("#607d69")
	match GameState.egg_kind(egg):
		"fusion":
			return Color("#824ca0")
		"fire":
			return Color("#d8492f")
		"water":
			return Color("#168ec8")
		"earth":
			return Color("#8b633d")
		"ice":
			return Color("#3187b8")
	return UiTokens.PINK_DARK


func _burst_confetti(origin: Vector2, piece_count: int, layer: int) -> void:
	var colors := [
		UiTokens.PINK,
		UiTokens.GOLD,
		UiTokens.MINT,
		UiTokens.SKY,
		Color("#9b7ede"),
		UiTokens.CREAM,
	]
	for piece_index in piece_count:
		var piece := PIXEL_ART.ConfettiPiece.new()
		piece.position = origin + Vector2(
			random.randf_range(-18.0, 18.0),
			random.randf_range(-8.0, 8.0)
		)
		piece.size = Vector2(random.randi_range(10, 17), random.randi_range(16, 27))
		piece.velocity = Vector2(
			random.randf_range(-330.0, 330.0),
			random.randf_range(-570.0, -280.0)
		)
		piece.spin = random.randf_range(-9.0, 9.0)
		piece.piece_color = colors[piece_index % colors.size()]
		piece.z_index = layer
		add_child(piece)
