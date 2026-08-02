extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")


func build() -> void:
	var top_shift := safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)
	var back := WidgetFactory.small_button("‹", Rect2(32, 44 + top_shift, 78, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("den", {}))
	add_child(back)
	var title := WidgetFactory.label(
		tr_text("EGGS_TITLE"), 47, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	add_child(title)
	var count := WidgetFactory.label(
		tr_text("EGG_COUNT", {"count": GameState.eggs.size()}),
		22,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	count.position = Vector2(0, 130 + top_shift)
	count.size = Vector2(720, 34)
	add_child(count)

	if GameState.eggs.is_empty():
		_build_empty(top_shift)
		return
	_build_list(top_shift)


func _build_empty(top_shift: float) -> void:
	var empty_panel := Panel.new()
	empty_panel.position = Vector2(60, 250 + top_shift)
	empty_panel.size = Vector2(600, 300)
	empty_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 20, 7)
	)
	add_child(empty_panel)
	var empty_text := WidgetFactory.label(
		tr_text("NO_EGGS"), 32, UiTokens.PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	empty_text.position = Vector2(30, 45)
	empty_text.size = Vector2(540, 60)
	empty_panel.add_child(empty_text)
	var hint := WidgetFactory.label(
		tr_text("FIND_EGG_IN_SHOP"), 24, UiTokens.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	hint.position = Vector2(45, 120)
	hint.size = Vector2(510, 75)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_panel.add_child(hint)
	var shop := WidgetFactory.button(
		tr_text("NAV_SHOP"),
		Rect2(80, 620 + top_shift, 560, 110),
		Color("#8ed5aa"),
		Color("#4d9a70")
	)
	shop.pressed.connect(navigate.bind("shop", {}))
	add_child(shop)


func _build_list(top_shift: float) -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 185 + top_shift)
	scroll.size = Vector2(720, maxf(420.0, canvas_size.y - 185.0 - top_shift))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var content := Control.new()
	content.custom_minimum_size = Vector2(720, maxf(520.0, 42.0 + GameState.eggs.size() * 238.0))
	scroll.add_child(content)

	for index in GameState.eggs.size():
		var egg: Dictionary = GameState.eggs[index]
		var card := Button.new()
		card.position = Vector2(48, 22 + index * 238)
		card.size = Vector2(624, 210)
		card.focus_mode = Control.FOCUS_NONE
		card.add_theme_stylebox_override(
			"normal",
			WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 20, 7)
		)
		card.add_theme_stylebox_override(
			"hover",
			WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.PINK_DARK, 20, 7)
		)
		card.add_theme_stylebox_override(
			"pressed",
			WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.PINK_DARK, 20, 3)
		)
		card.pressed.connect(navigate.bind(
			"egg_detail",
			{"egg_id": String(egg.get("id", ""))}
		))
		content.add_child(card)
		_add_egg_art(card, egg, Rect2(25, 18, 130, 170))
		var egg_name := WidgetFactory.label(
			tr_text(GameState.egg_name_key(egg)),
			26,
			_egg_accent_color(egg),
			HORIZONTAL_ALIGNMENT_LEFT,
			UiTokens.FONT_BOLD
		)
		egg_name.position = Vector2(180, 28)
		egg_name.size = Vector2(405, 52)
		egg_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(egg_name)
		var progress := int(egg.get("progress_steps", 0))
		var required := int(egg.get("required_steps", GameState.EGG_REQUIRED_STEPS))
		var progress_text := WidgetFactory.label(
			tr_text("EGG_NOT_STARTED") if int(egg.get("incubation_start", 0)) == 0 else tr_text(
				"EGG_STEP_PROGRESS",
				{"current": progress, "required": required}
			),
			22,
			UiTokens.INK_SOFT,
			HORIZONTAL_ALIGNMENT_LEFT,
			UiTokens.FONT_BOLD
		)
		progress_text.position = Vector2(180, 88)
		progress_text.size = Vector2(405, 76)
		progress_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(progress_text)


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
