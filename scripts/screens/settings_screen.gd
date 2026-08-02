extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")

var reset_button: Button
var reset_hint: Label
var reset_armed := false


func build() -> void:
	var top_shift := safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)

	var back := WidgetFactory.small_button("‹", Rect2(32, 44 + top_shift, 78, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("main", {}))
	add_child(back)
	var title := WidgetFactory.label(
		tr_text("SETTINGS_TITLE"), 47, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	add_child(title)

	_build_language_panel(top_shift)
	_build_reset_panel(top_shift)


func _build_language_panel(top_shift: float) -> void:
	var panel := Panel.new()
	panel.position = Vector2(48, 170 + top_shift)
	panel.size = Vector2(624, 330)
	panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 22, 8)
	)
	add_child(panel)
	var heading := WidgetFactory.label(
		tr_text("LANGUAGE"), 36, UiTokens.PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	heading.position = Vector2(24, 28)
	heading.size = Vector2(576, 52)
	panel.add_child(heading)
	var hint := WidgetFactory.label(
		tr_text("LANGUAGE_HINT"), 23, UiTokens.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	hint.position = Vector2(32, 92)
	hint.size = Vector2(560, 52)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(hint)

	var active_locale := Localization.get_locale()
	var english := WidgetFactory.button(
		tr_text("LANGUAGE_ENGLISH"),
		Rect2(28, 180, 270, 104),
		UiTokens.PINK if active_locale == "en" else UiTokens.CREAM,
		UiTokens.PINK_DARK if active_locale == "en" else UiTokens.INK_SOFT
	)
	if active_locale != "en":
		_set_light_button_text(english)
	english.pressed.connect(Localization.set_locale.bind("en"))
	panel.add_child(english)
	var german := WidgetFactory.button(
		tr_text("LANGUAGE_GERMAN"),
		Rect2(326, 180, 270, 104),
		UiTokens.PINK if active_locale == "de" else UiTokens.CREAM,
		UiTokens.PINK_DARK if active_locale == "de" else UiTokens.INK_SOFT
	)
	if active_locale != "de":
		_set_light_button_text(german)
	german.pressed.connect(Localization.set_locale.bind("de"))
	panel.add_child(german)


func _set_light_button_text(button: Button) -> void:
	button.add_theme_color_override("font_color", UiTokens.INK)
	button.add_theme_color_override("font_hover_color", UiTokens.INK)
	button.add_theme_color_override("font_pressed_color", UiTokens.INK)


func _build_reset_panel(top_shift: float) -> void:
	var panel := Panel.new()
	panel.position = Vector2(48, 550 + top_shift)
	panel.size = Vector2(624, 430)
	panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color("#fff4ed"), UiTokens.INK, 22, 8)
	)
	add_child(panel)
	var heading := WidgetFactory.label(
		tr_text("RESET_APP_TITLE"), 36, Color("#c64d4d"), HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	heading.position = Vector2(24, 28)
	heading.size = Vector2(576, 52)
	panel.add_child(heading)
	var description := WidgetFactory.label(
		tr_text("RESET_APP_DESCRIPTION"),
		19,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	description.position = Vector2(24, 86)
	description.size = Vector2(576, 132)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(description)
	reset_hint = WidgetFactory.label(
		tr_text("RESET_APP_WARNING"),
		21,
		Color("#a64343"),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	reset_hint.position = Vector2(42, 222)
	reset_hint.size = Vector2(540, 54)
	reset_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(reset_hint)
	reset_button = WidgetFactory.button(
		tr_text("RESET_APP"),
		Rect2(72, 286, 480, 108),
		Color("#ef7b6f"),
		Color("#b74444")
	)
	reset_button.pressed.connect(_on_reset_pressed)
	panel.add_child(reset_button)


func _on_reset_pressed() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = tr_text("RESET_APP_CONFIRM")
		reset_hint.text = tr_text("RESET_APP_CONFIRM_HINT")
		return
	navigate("reset_app", {})
