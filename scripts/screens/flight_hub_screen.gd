extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")


func build() -> void:
	var selected_dragon_id := String(context.get("selected_dragon_id", "luma"))
	var selected_dragon := GameState.get_dragon(selected_dragon_id)
	var top_y := safe_top_y(32.0)
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)
	var wash := ColorRect.new()
	wash.size = canvas_size
	wash.color = Color(0.98, 0.69, 0.82, 0.14)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, top_y)
	top_panel.size = Vector2(672, 104)
	top_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color(1, 0.98, 0.91, 0.97), UiTokens.INK, 18, 6)
	)
	add_child(top_panel)
	var back := WidgetFactory.small_button("‹", Rect2(16, 16, 74, 68), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("flight_select", {}))
	top_panel.add_child(back)
	var title := WidgetFactory.label(
		tr_text("FLIGHT_HUB_TITLE"), 40, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	title.position = Vector2(96, 14)
	title.size = Vector2(480, 70)
	top_panel.add_child(title)

	var dragon := WidgetFactory.texture_rect(
		GameState.flight_texture(selected_dragon),
		Rect2(90, top_y + 150, 540, 330),
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	dragon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(dragon)
	var name := WidgetFactory.label(
		tr_text(GameState.dragon_name_key(selected_dragon)),
		31,
		UiTokens.PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	name.position = Vector2(110, top_y + 442)
	name.size = Vector2(500, 44)
	add_child(name)

	var xp := GameState.get_flight_xp(selected_dragon_id)
	var level := GameState.get_flight_level(selected_dragon_id)
	var progress := xp % GameState.FLIGHT_XP_PER_LEVEL
	var stats := Panel.new()
	stats.position = Vector2(72, top_y + 500)
	stats.size = Vector2(576, 150)
	stats.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 18, 6)
	)
	add_child(stats)
	var level_label := WidgetFactory.label(
		tr_text("FLIGHT_LEVEL", {"level": level}),
		34,
		UiTokens.PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	level_label.position = Vector2(20, 12)
	level_label.size = Vector2(536, 48)
	stats.add_child(level_label)
	var xp_label := WidgetFactory.label(
		tr_text("FLIGHT_XP_PROGRESS", {
			"current": progress,
			"required": GameState.FLIGHT_XP_PER_LEVEL,
		}),
		23,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	xp_label.position = Vector2(20, 62)
	xp_label.size = Vector2(536, 36)
	stats.add_child(xp_label)
	var xp_bar := ProgressBar.new()
	xp_bar.position = Vector2(34, 105)
	xp_bar.size = Vector2(508, 27)
	xp_bar.max_value = GameState.FLIGHT_XP_PER_LEVEL
	xp_bar.value = progress
	xp_bar.show_percentage = false
	xp_bar.add_theme_stylebox_override(
		"background",
		WidgetFactory.panel_style(Color("#e3d4b8"), UiTokens.INK, 7, 0)
	)
	xp_bar.add_theme_stylebox_override(
		"fill",
		WidgetFactory.panel_style(UiTokens.PINK, UiTokens.INK, 7, 0)
	)
	stats.add_child(xp_bar)

	var training := WidgetFactory.button(
		tr_text("FLIGHT_TRAINING"),
		Rect2(72, top_y + 700, 576, 118),
		UiTokens.PINK,
		UiTokens.PINK_DARK
	)
	training.pressed.connect(navigate.bind("flight_training", {}))
	add_child(training)
	WidgetFactory.add_button_caption(training, tr_text("FLIGHT_TRAINING_CAPTION"))

	var contest_goal := GameState.flight_contest_goal(selected_dragon_id)
	var contest_complete := contest_goal <= 0
	var contest := WidgetFactory.button(
		tr_text("FLIGHT_CONTEST"),
		Rect2(72, top_y + 855, 576, 118),
		UiTokens.GOLD,
		Color("#d38a38")
	)
	contest.disabled = contest_complete or not GameState.can_enter_flight_contest(selected_dragon_id)
	contest.pressed.connect(navigate.bind("flight_contest", {}))
	add_child(contest)
	WidgetFactory.add_button_caption(
		contest,
		tr_text("FLIGHT_CHAMPION")
		if contest_complete
		else (
			tr_text("FLIGHT_CONTEST_GOAL", {"meters": contest_goal})
			if not contest.disabled
			else tr_text(
				"FLIGHT_CONTEST_LOCKED_GOAL",
				{
					"level": GameState.flight_contest_required_level(selected_dragon_id),
					"meters": contest_goal,
				}
			)
		)
	)
