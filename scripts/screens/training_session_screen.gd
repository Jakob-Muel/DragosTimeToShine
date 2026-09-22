extends GameScreen

var game: TalentMinigame
var definition: TrainingCategoryDefinition
var selected_dragon_id := "luma"
var talent_id: StringName
var return_route := "main"
var session: Dictionary = {}
var score_label: Label
var lives_label: Label
var result_overlay: Control
var _resolved := false


func build() -> void:
	selected_dragon_id = String(context.get("dragon_id", context.get("selected_dragon_id", "luma")))
	talent_id = StringName(String(context.get("talent_id", "")))
	return_route = String(context.get("return_route", "main"))
	definition = GameState.catalog.get_training_category(talent_id)
	if definition == null or definition.minigame_scene == null:
		_show_unavailable()
		return
	session = GameState.create_training_session(selected_dragon_id, talent_id)
	if session.is_empty():
		_show_unavailable()
		return
	var instance := definition.minigame_scene.instantiate()
	game = instance as TalentMinigame
	if game == null:
		instance.free()
		_show_unavailable()
		return
	session["appearance"] = {"seed": ProceduralDragonTextures.seed_for(GameState.get_dragon(selected_dragon_id))}
	var game_top := safe_top_y(32.0) + 126.0
	game.position = Vector2(0, game_top)
	game.size = Vector2(canvas_size.x, safe_bottom_y(0.0) - game_top)
	game.configure(session)
	game.score_changed.connect(_on_score_changed)
	game.status_changed.connect(_on_status_changed)
	game.run_completed.connect(_on_run_completed)
	game.run_cancelled.connect(_on_run_cancelled)
	add_child(game)
	_build_header()
	_build_hint(game_top)
	game.start_run()


func _build_header() -> void:
	var header := Panel.new()
	header.position = Vector2(24, safe_top_y(32.0))
	header.size = Vector2(canvas_size.x - 48, 104)
	header.z_index = 100
	header.add_theme_stylebox_override("panel", WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.INK, 18, 6))
	add_child(header)
	var back := WidgetFactory.small_button("‹", Rect2(16, 16, 74, 68), UiTokens.CREAM)
	back.pressed.connect(_leave)
	header.add_child(back)
	_add_label(header, tr_text(String(definition.name_key)), Rect2(100, 8, 460, 44), 32, UiTokens.INK)
	score_label = _add_label(header, "", Rect2(100, 54, 330, 34), 23, UiTokens.INK_SOFT)
	lives_label = _add_label(header, "", Rect2(442, 54, 200, 34), 23, UiTokens.PINK_DARK)
	_on_score_changed(0)


func _build_hint(game_top: float) -> void:
	if definition.instruction_key.is_empty():
		return
	var hint := Panel.new()
	hint.position = Vector2(68, game_top + 20)
	hint.size = Vector2(canvas_size.x - 136, 72)
	hint.z_index = 90
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_stylebox_override("panel", WidgetFactory.panel_style(Color("#382b3d"), UiTokens.INK, 12, 3))
	add_child(hint)
	var label := _add_label(hint, tr_text(String(definition.instruction_key)), Rect2(12, 4, hint.size.x - 24, 64), 20, UiTokens.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fade := create_tween()
	fade.tween_interval(3.0)
	fade.tween_property(hint, "modulate:a", 0.0, 0.5)


func _on_score_changed(score: int) -> void:
	if is_instance_valid(score_label):
		score_label.text = tr_text("TRAINING_LIVE_SCORE", {"score": score})


func _on_status_changed(status: Dictionary) -> void:
	if is_instance_valid(lives_label):
		lives_label.text = "♥ ".repeat(clampi(int(status.get("remaining_attempts", 0)), 0, 5)).strip_edges()


func _on_run_completed(result: Dictionary) -> void:
	if _resolved or not is_inside_tree():
		return
	# Bind the result to this exact session, even if a minigame emits a malformed signal.
	for key: String in ["run_id", "dragon_id", "talent_id"]:
		if String(result.get(key, "")) != String(session.get(key, "")):
			return
	var summary := GameState.apply_training_result(selected_dragon_id, result, String(context.get("attribute_id", "")))
	if not bool(summary.get("accepted", false)):
		return
	_resolved = true
	game.process_mode = Node.PROCESS_MODE_DISABLED
	_show_result(summary)


func _on_run_cancelled() -> void:
	if not _resolved:
		_leave()


func _leave() -> void:
	_resolved = true
	if is_instance_valid(game):
		game.cancel_run()
		game.process_mode = Node.PROCESS_MODE_DISABLED
	navigate(return_route, {"selected_dragon_id": selected_dragon_id})


func _exit_tree() -> void:
	_resolved = true
	if is_instance_valid(game):
		game.cancel_run()


func _retry() -> void:
	navigate("training_session", {
		"talent_id": String(talent_id), "dragon_id": selected_dragon_id,
		"return_route": return_route, "attribute_id": String(context.get("attribute_id", "")),
	})


func _show_result(summary: Dictionary) -> void:
	result_overlay = Control.new()
	result_overlay.size = canvas_size
	result_overlay.z_index = 4000
	add_child(result_overlay)
	var dim := ColorRect.new()
	dim.size = canvas_size
	dim.color = Color(0.10, 0.07, 0.14, 0.72)
	result_overlay.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(60, safe_top_y(24) + (safe_bottom_y() - safe_top_y(24) - 620) * 0.5)
	panel.size = Vector2(canvas_size.x - 120, 620)
	panel.add_theme_stylebox_override("panel", WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 24, 10))
	result_overlay.add_child(panel)
	_add_label(panel, tr_text("TRAINING_ROUND_OVER"), Rect2(24, 26, 552, 54), 36, UiTokens.PINK_DARK)
	_add_label(panel, "★".repeat(clampi(int(summary.get("stars", 1)), 1, 5)), Rect2(24, 92, 552, 60), 42, UiTokens.GOLD_DARK)
	var feedback_key := "TRAINING_NEW_RECORD" if bool(summary.get("new_record", false)) else "TRAINING_KEEP_GOING"
	_add_label(panel, tr_text(feedback_key), Rect2(24, 164, 552, 44), 25, UiTokens.INK)
	_add_label(panel, tr_text("TRAINING_RECORD", {"score": summary.get("raw_score", 0), "best": summary.get("best_score", 0)}), Rect2(24, 220, 552, 44), 25, UiTokens.INK)
	_add_label(panel, tr_text("TRAINING_PROGRESS", {"xp": summary.get("xp_earned", 0), "level": summary.get("level", 0)}), Rect2(24, 276, 552, 44), 23, UiTokens.INK_SOFT)
	_add_label(panel, tr_text("ATTRIBUTE_GAIN", {"gain": summary.get("attribute_gain", 0)}), Rect2(24, 316, 552, 32), 21, UiTokens.INK)
	var retry := WidgetFactory.button(tr_text("TRAINING_RETRY"), Rect2(80, 358, 440, 88), UiTokens.PINK, UiTokens.PINK_DARK)
	retry.pressed.connect(_retry)
	panel.add_child(retry)
	var back := WidgetFactory.button(tr_text("TRAINING_BACK"), Rect2(80, 472, 440, 88), UiTokens.GREEN, Color("#32654b"))
	back.pressed.connect(_leave)
	panel.add_child(back)


func _show_unavailable() -> void:
	_resolved = true
	_add_label(self, tr_text("TRAINING_UNAVAILABLE"), Rect2(60, safe_top_y(32) + 160, 600, 100), 28, UiTokens.INK)
	var back := WidgetFactory.button(tr_text("TRAINING_BACK"), Rect2(140, safe_top_y(32) + 300, 440, 88), UiTokens.PINK, UiTokens.PINK_DARK)
	back.pressed.connect(_leave)
	add_child(back)


func _add_label(parent: Node, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := WidgetFactory.label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD)
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func debug_game() -> TalentMinigame:
	return game
