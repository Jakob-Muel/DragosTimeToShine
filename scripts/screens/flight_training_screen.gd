extends GameScreen

const FLIGHT_GAME := preload("res://scripts/ui/flight_game.gd")

var selected_dragon_id := "luma"
var run_start_level := 0
var score_label: Label


func build() -> void:
	selected_dragon_id = String(context.get("selected_dragon_id", "luma"))
	run_start_level = GameState.get_flight_level(selected_dragon_id)
	var top_y := safe_top_y(32.0)
	var game_top := top_y + 126.0
	var game := FLIGHT_GAME.new()
	game.position = Vector2(0, game_top)
	game.size = Vector2(canvas_size.x, canvas_size.y - game_top)
	game.dragon_texture = GameState.flight_texture(GameState.get_dragon(selected_dragon_id))
	game.score_changed.connect(_on_score_changed)
	game.run_finished.connect(_on_run_finished)
	add_child(game)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, top_y)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color(1, 0.98, 0.91, 0.97), UiTokens.INK, 18, 6)
	)
	add_child(top_panel)
	var back := WidgetFactory.small_button("‹", Rect2(16, 16, 74, 68), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("flight_hub", {}))
	top_panel.add_child(back)
	var title := WidgetFactory.label(
		tr_text("FLIGHT_TRAINING"), 38, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	title.position = Vector2(94, 8)
	title.size = Vector2(484, 48)
	top_panel.add_child(title)
	score_label = WidgetFactory.label(
		tr_text("FLIGHT_LIVE_SCORE", {"xp": 0, "level": run_start_level}),
		22,
		UiTokens.PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	score_label.position = Vector2(94, 54)
	score_label.size = Vector2(484, 34)
	top_panel.add_child(score_label)

	var tap_hint := Panel.new()
	tap_hint.position = Vector2(82, game_top + 44)
	tap_hint.size = Vector2(556, 72)
	tap_hint.z_index = 90
	tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tap_hint.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color(0.19, 0.13, 0.25, 0.88), UiTokens.INK, 12, 3)
	)
	add_child(tap_hint)
	var hint_label := WidgetFactory.label(
		tr_text("FLIGHT_TAP_HINT"), 20, UiTokens.WHITE, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tap_hint.add_child(hint_label)
	var hide_hint := create_tween()
	hide_hint.tween_interval(2.2)
	hide_hint.tween_property(tap_hint, "modulate:a", 0.0, 0.5)


func _on_score_changed(score: int) -> void:
	GameState.add_flight_xp(selected_dragon_id, 1)
	if is_instance_valid(score_label):
		score_label.text = tr_text(
			"FLIGHT_LIVE_SCORE",
			{"xp": score, "level": GameState.get_flight_level(selected_dragon_id)}
		)


func _on_run_finished(score: int, _completed: bool) -> void:
	var previous_level := run_start_level
	var new_level := GameState.get_flight_level(selected_dragon_id)
	var overlay := Control.new()
	overlay.size = canvas_size
	overlay.z_index = 4000
	add_child(overlay)
	var dim := ColorRect.new()
	dim.size = canvas_size
	dim.color = Color(0.10, 0.07, 0.14, 0.68)
	overlay.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(60, canvas_size.y * 0.5 - 285)
	panel.size = Vector2(600, 570)
	panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 24, 10)
	)
	overlay.add_child(panel)
	var result_title := WidgetFactory.label(
		tr_text("FLIGHT_ROUND_OVER"), 40, UiTokens.PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	result_title.position = Vector2(30, 40)
	result_title.size = Vector2(540, 64)
	panel.add_child(result_title)
	var xp_result := WidgetFactory.label(
		tr_text("FLIGHT_XP_EARNED", {"xp": score}),
		30,
		UiTokens.GOLD,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	xp_result.position = Vector2(30, 120)
	xp_result.size = Vector2(540, 54)
	panel.add_child(xp_result)
	var level_result := WidgetFactory.label(
		tr_text("FLIGHT_LEVEL_UP", {"level": new_level}) if new_level > previous_level else tr_text(
			"FLIGHT_LEVEL",
			{"level": new_level}
		),
		27,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	level_result.position = Vector2(30, 185)
	level_result.size = Vector2(540, 52)
	panel.add_child(level_result)
	var next_goal := GameState.flight_contest_goal(selected_dragon_id)
	var progress_text := tr_text("FLIGHT_CHAMPION")
	if next_goal > 0:
		progress_text = (
			tr_text("FLIGHT_CONTEST_READY_GOAL", {"meters": next_goal})
			if GameState.can_enter_flight_contest(selected_dragon_id)
			else tr_text(
				"FLIGHT_LEVELS_TO_GO_GOAL",
				{
					"count": maxi(
						0,
						GameState.flight_contest_required_level(selected_dragon_id) - new_level
					),
					"meters": next_goal,
				}
			)
		)
	var progress_note := WidgetFactory.label(
		progress_text,
		24,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	progress_note.position = Vector2(55, 245)
	progress_note.size = Vector2(490, 76)
	progress_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(progress_note)
	var retry := WidgetFactory.button(
		tr_text("FLIGHT_RETRY"), Rect2(80, 340, 440, 82), UiTokens.PINK, UiTokens.PINK_DARK
	)
	retry.add_theme_font_size_override("font_size", 31)
	retry.pressed.connect(navigate.bind("flight_training", {}))
	panel.add_child(retry)
	var hub := WidgetFactory.button(
		tr_text("FLIGHT_BACK_TO_HUB"),
		Rect2(80, 444, 440, 82),
		Color("#8ed5aa"),
		Color("#4d9a70")
	)
	hub.add_theme_font_size_override("font_size", 29)
	hub.pressed.connect(navigate.bind("flight_hub", {}))
	panel.add_child(hub)
