extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const DRAGON_TEXTURE := preload("res://assets/art/dragon_pink_hd.png")


func build() -> void:
	var top_shift := safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)
	var back := WidgetFactory.small_button("‹", Rect2(32, 44 + top_shift, 78, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("den", {}))
	add_child(back)
	var title := WidgetFactory.label(
		tr_text("DEN_DRAGONS"), 47, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	add_child(title)
	var count := WidgetFactory.label(
		tr_text("DEN_COUNT", {
			"owned": GameState.dragons.size(),
			"capacity": GameState.DRAGON_CAPACITY,
		}),
		22,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	count.position = Vector2(0, 130 + top_shift)
	count.size = Vector2(720, 34)
	add_child(count)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 174 + top_shift)
	scroll.size = Vector2(720, maxf(420.0, canvas_size.y - 174.0 - top_shift))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var content := Control.new()
	var dragon_rows := ceili(GameState.dragons.size() / 2.0)
	content.custom_minimum_size = Vector2(720, maxf(580.0, 142.0 + dragon_rows * 450.0))
	scroll.add_child(content)

	var info := Panel.new()
	info.position = Vector2(40, 10)
	info.size = Vector2(640, 84)
	info.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.INK, 14, 5)
	)
	content.add_child(info)
	var info_text := WidgetFactory.label(
		tr_text("DEN_INSTRUCTION"), 25, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	info_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	info.add_child(info_text)

	var dragon_count := GameState.dragons.size()
	var card_width := 624.0 if dragon_count == 1 else 300.0
	for index in dragon_count:
		var dragon_data: Dictionary = GameState.dragons[index]
		var dragon_texture := GameState.dragon_texture(dragon_data)
		if dragon_texture == null:
			dragon_texture = DRAGON_TEXTURE
		var uses_pixel_filter := not GameState.dragon_has_type(dragon_data, &"sunwing")
		var accent := _dragon_accent_color(dragon_data)
		var column := index % 2
		var row := index / 2
		var card_x := 48.0 if dragon_count == 1 else 42.0 + column * 330.0
		var card_y := 128.0 + row * 450.0
		var card := Button.new()
		card.position = Vector2(card_x, card_y)
		card.size = Vector2(card_width, 410)
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.add_theme_stylebox_override(
			"normal",
			WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 20, 8)
		)
		card.add_theme_stylebox_override(
			"hover",
			WidgetFactory.panel_style(Color("#fff9de"), UiTokens.PINK_DARK, 20, 8)
		)
		card.add_theme_stylebox_override(
			"pressed",
			WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.PINK_DARK, 20, 3)
		)
		card.pressed.connect(navigate.bind(
			"select_dragon",
			{"dragon_id": String(dragon_data.get("id", "luma"))}
		))
		content.add_child(card)

		var portrait_back := Panel.new()
		portrait_back.position = Vector2(20, 22)
		portrait_back.size = Vector2(card_width - 40.0, 245)
		portrait_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_back.add_theme_stylebox_override(
			"panel",
			WidgetFactory.panel_style(
				_dragon_portrait_color(dragon_data),
				UiTokens.INK,
				16,
				3
			)
		)
		card.add_child(portrait_back)
		var portrait := WidgetFactory.dragon_presentation(
			dragon_texture,
			Rect2(20, 5, portrait_back.size.x - 40.0, 230),
			CanvasItem.TEXTURE_FILTER_NEAREST
			if uses_pixel_filter
			else CanvasItem.TEXTURE_FILTER_LINEAR
		)
		portrait_back.add_child(portrait)
		var dragon_name := WidgetFactory.label(
			tr_text(GameState.dragon_name_key(dragon_data)),
			42 if dragon_count == 1 else 34,
			accent,
			HORIZONTAL_ALIGNMENT_CENTER,
			UiTokens.FONT_BOLD
		)
		dragon_name.position = Vector2(12, 278)
		dragon_name.size = Vector2(card_width - 24.0, 54)
		card.add_child(dragon_name)
		var visit := WidgetFactory.label(
			tr_text("VISIT_ISLAND"), 23, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
		)
		visit.position = Vector2(10, 342)
		visit.size = Vector2(card_width - 20.0, 40)
		card.add_child(visit)


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
	return UiTokens.PINK_DARK


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
