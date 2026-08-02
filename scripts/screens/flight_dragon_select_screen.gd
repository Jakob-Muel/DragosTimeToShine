extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")


func build() -> void:
	var top_shift := safe_top_y(40.0) - 40.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)

	var back := WidgetFactory.small_button("‹", Rect2(32, 40 + top_shift, 78, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("main", {}))
	add_child(back)
	var title := WidgetFactory.label(
		tr_text("FLIGHT_SELECT_TITLE"),
		43,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	title.position = Vector2(115, 42 + top_shift)
	title.size = Vector2(490, 62)
	add_child(title)
	var hint := WidgetFactory.label(
		tr_text("FLIGHT_SELECT_HINT"),
		24,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	hint.position = Vector2(45, 122 + top_shift)
	hint.size = Vector2(630, 58)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 192 + top_shift)
	scroll.size = Vector2(720, maxf(420.0, canvas_size.y - 192.0 - top_shift))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var content := Control.new()
	var rows := ceili(GameState.dragons.size() / 2.0)
	content.custom_minimum_size = Vector2(720, maxf(650.0, rows * 350.0 + 40.0))
	scroll.add_child(content)

	for index in GameState.dragons.size():
		_add_dragon_card(content, GameState.dragons[index], index)


func _add_dragon_card(parent: Control, dragon: Dictionary, index: int) -> void:
	var column := index % 2
	var row := index / 2
	var card := Button.new()
	card.position = Vector2(38 + column * 334, 16 + row * 350)
	card.size = Vector2(310, 322)
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override(
		"normal",
		WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 20, 7)
	)
	card.add_theme_stylebox_override(
		"hover",
		WidgetFactory.panel_style(Color("#fff9de"), UiTokens.PINK_DARK, 20, 7)
	)
	card.add_theme_stylebox_override(
		"pressed",
		WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.PINK_DARK, 20, 3)
	)
	card.pressed.connect(navigate.bind(
		"select_flight_dragon",
		{"dragon_id": String(dragon.get("id", "luma"))}
	))
	parent.add_child(card)

	var portrait_back := Panel.new()
	portrait_back.position = Vector2(18, 18)
	portrait_back.size = Vector2(274, 156)
	portrait_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_back.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color("#dff5e8"), UiTokens.INK, 14, 3)
	)
	card.add_child(portrait_back)
	var texture := GameState.flight_texture(dragon)
	if texture != null:
		var portrait := WidgetFactory.texture_rect(
			texture,
			Rect2(15, 8, 244, 140),
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait_back.add_child(portrait)

	var name := WidgetFactory.label(
		tr_text(GameState.dragon_name_key(dragon)),
		31,
		UiTokens.PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	name.position = Vector2(10, 184)
	name.size = Vector2(290, 44)
	card.add_child(name)
	var dragon_id := String(dragon.get("id", "luma"))
	var level := WidgetFactory.label(
		tr_text("FLIGHT_LEVEL", {"level": GameState.get_flight_level(dragon_id)}),
		22,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	level.position = Vector2(10, 229)
	level.size = Vector2(290, 34)
	card.add_child(level)
	var goal := GameState.flight_contest_goal(dragon_id)
	var goal_text := (
		tr_text("FLIGHT_CHAMPION")
		if goal <= 0
		else tr_text("FLIGHT_NEXT_GOAL", {"meters": goal})
	)
	var goal_label := WidgetFactory.label(
		goal_text,
		20,
		UiTokens.GOLD if goal > 0 else Color("#4d9a70"),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	goal_label.position = Vector2(8, 271)
	goal_label.size = Vector2(294, 34)
	card.add_child(goal_label)
