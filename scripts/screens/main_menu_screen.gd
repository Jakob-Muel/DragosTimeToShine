extends GameScreen

const ISLAND_TEXTURE := preload("res://assets/art/dragon_island_hd.png")
const DRAGON_TEXTURE := preload("res://assets/art/dragon_pink_hd.png")
const BUILD_INFO := preload("res://scripts/build_info.gd")


func build() -> void:
	var top_y := safe_top_y(30.0)
	var safe_footer_y := safe_bottom_y(26.0)

	var sky_fill := ColorRect.new()
	sky_fill.size = canvas_size
	sky_fill.color = UiTokens.SKY
	add_child(sky_fill)

	# Covering the canvas removes the old light-blue rectangle below the source
	# artwork. The important island and clouds remain centered at every aspect.
	var island := WidgetFactory.texture_rect(
		ISLAND_TEXTURE,
		Rect2(Vector2.ZERO, canvas_size),
		TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)
	island.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(island)

	var atmosphere := ColorRect.new()
	atmosphere.size = canvas_size
	atmosphere.color = Color(0.92, 0.98, 0.94, 0.08)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)

	_build_top_bar(top_y)
	_build_brand(top_y)

	var dragon_top := top_y + 216.0
	var dragon := WidgetFactory.dragon_presentation(
		DRAGON_TEXTURE,
		Rect2(170, dragon_top, 380, 330),
		CanvasItem.TEXTURE_FILTER_LINEAR
	)
	add_child(dragon)

	var action_y := clampf(canvas_size.y - 420.0, 850.0, 1100.0)
	var greeting_y := minf(top_y + 558.0, action_y - 112.0)
	_build_greeting(greeting_y)
	_build_actions(action_y)

	var version := WidgetFactory.label(
		BUILD_INFO.VERSION,
		17,
		Color(UiTokens.INK_SOFT, 0.70),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	version.position = Vector2(0, safe_footer_y - 36.0)
	version.size = Vector2(canvas_size.x, 28)
	add_child(version)


func _build_top_bar(top_y: float) -> void:
	WidgetFactory.add_resource_pill(
		self,
		Vector2(30, top_y),
		GameState.gems,
		"gem",
		UiTokens.PINK_DARK
	)
	WidgetFactory.add_resource_pill(
		self,
		Vector2(512, top_y),
		GameState.gold,
		"coin",
		UiTokens.GOLD_DARK
	)

	var settings_button := WidgetFactory.small_button(
		"⚙",
		Rect2(319, top_y, 82, 82),
		UiTokens.CREAM
	)
	settings_button.add_theme_font_size_override("font_size", 35)
	settings_button.tooltip_text = tr_text("SETTINGS_TITLE")
	settings_button.pressed.connect(navigate.bind("settings", {}))
	add_child(settings_button)


func _build_brand(top_y: float) -> void:
	var title := WidgetFactory.label(
		tr_text("BRAND_NAME"),
		76,
		UiTokens.PINK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_HEAVY
	)
	title.position = Vector2(30, top_y + 88.0)
	title.size = Vector2(660, 92)
	title.add_theme_color_override("font_outline_color", UiTokens.INK)
	title.add_theme_constant_override("outline_size", 3)
	add_child(title)

	var subtitle := WidgetFactory.label(
		tr_text("BRAND_SUBTITLE"),
		24,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	subtitle.position = Vector2(70, top_y + 167.0)
	subtitle.size = Vector2(580, 42)
	add_child(subtitle)


func _build_greeting(y: float) -> void:
	var prompt_panel := Panel.new()
	prompt_panel.position = Vector2(88, y)
	prompt_panel.size = Vector2(544, 78)
	prompt_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(
			Color(1, 0.98, 0.91, 0.95),
			UiTokens.CREAM_DEEP.darkened(0.34),
			28,
			5
		)
	)
	add_child(prompt_panel)

	var greeting := WidgetFactory.label(
		tr_text("MAIN_GREETING"),
		25,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	greeting.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE,
		12
	)
	prompt_panel.add_child(greeting)


func _build_actions(y: float) -> void:
	var den_button := WidgetFactory.button(
		tr_text("NAV_DEN"),
		Rect2(52, y, 616, 106),
		UiTokens.PINK,
		UiTokens.PINK_DARK
	)
	den_button.pressed.connect(navigate.bind("den", {}))
	add_child(den_button)
	WidgetFactory.add_button_caption(den_button, tr_text("NAV_DEN_CAPTION"))

	var lower_y := y + 128.0
	var shop_button := WidgetFactory.button(
		tr_text("NAV_SHOP"),
		Rect2(52, lower_y, 298, 106),
		UiTokens.GREEN,
		Color("#32654b")
	)
	shop_button.pressed.connect(navigate.bind("shop", {}))
	add_child(shop_button)
	WidgetFactory.add_button_caption(shop_button, tr_text("SHOP_CAPTION"))

	var contest_button := WidgetFactory.button(
		tr_text("NAV_CONTEST"),
		Rect2(370, lower_y, 298, 106),
		UiTokens.GOLD,
		UiTokens.GOLD_DARK
	)
	contest_button.pressed.connect(navigate.bind("flight_select", {}))
	add_child(contest_button)
	WidgetFactory.add_button_caption(contest_button, tr_text("CONTEST_CAPTION"))
