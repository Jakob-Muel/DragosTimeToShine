extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")


func build() -> void:
	var top_shift := safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)

	var back := WidgetFactory.small_button("‹", Rect2(32, 44 + top_shift, 78, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("main", {}))
	add_child(back)
	var title := WidgetFactory.label(
		tr_text("DEN_TITLE"), 40, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	title.position = Vector2(122, 46 + top_shift)
	title.size = Vector2(568, 67)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(title)

	var info := Panel.new()
	info.position = Vector2(40, 168 + top_shift)
	info.size = Vector2(640, 84)
	info.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.INK, 14, 5)
	)
	add_child(info)
	var info_text := WidgetFactory.label(
		tr_text("DEN_HUB_INSTRUCTION"), 27, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD
	)
	info_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	info.add_child(info_text)

	var dragons_button := WidgetFactory.button(
		tr_text("DEN_DRAGONS"),
		Rect2(72, 286 + top_shift, 576, 116),
		UiTokens.PINK,
		UiTokens.PINK_DARK
	)
	dragons_button.pressed.connect(navigate.bind("dragons", {}))
	add_child(dragons_button)
	WidgetFactory.add_button_caption(
		dragons_button,
		tr_text("DEN_DRAGONS_CAPTION", {"count": GameState.dragons.size()})
	)

	var eggs_button := WidgetFactory.button(
		tr_text("DEN_EGGS"),
		Rect2(72, 424 + top_shift, 576, 116),
		UiTokens.GOLD,
		Color("#d38a38")
	)
	eggs_button.pressed.connect(navigate.bind("eggs", {}))
	add_child(eggs_button)
	WidgetFactory.add_button_caption(
		eggs_button,
		tr_text("DEN_EGGS_CAPTION", {"count": GameState.eggs.size()})
	)

	var fusion_button := WidgetFactory.button(
		tr_text("DEN_FUSION"),
		Rect2(72, 562 + top_shift, 576, 116),
		Color("#9a68bd"),
		Color("#67447f")
	)
	fusion_button.pressed.connect(navigate.bind("fusion", {}))
	add_child(fusion_button)
	WidgetFactory.add_button_caption(
		fusion_button,
		tr_text("DEN_FUSION_CAPTION", {"count": GameState.fusion_stars})
	)

	var shop_button := WidgetFactory.button(
		tr_text("NAV_SHOP"),
		Rect2(120, 720 + top_shift, 480, 106),
		Color("#8ed5aa"),
		Color("#4d9a70")
	)
	shop_button.pressed.connect(navigate.bind("shop", {}))
	add_child(shop_button)
	WidgetFactory.add_button_caption(shop_button, tr_text("SHOP_CAPTION"))
