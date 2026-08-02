extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const FIRE_EGG_TEXTURE := preload("res://assets/art/fire/fire_egg.png")
const WATER_EGG_TEXTURE := preload("res://assets/art/water/water_egg.png")
const EARTH_EGG_TEXTURE := preload("res://assets/art/earth/earth_egg.png")

const CARD_HEIGHT := 268.0
const CARD_GAP := 22.0


func build() -> void:
	var top_y := safe_top_y(32.0)
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)

	_build_header(top_y)

	var scroll_top := top_y + 172.0
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, scroll_top)
	scroll.size = Vector2(720, maxf(360.0, safe_bottom_y(18.0) - scroll_top))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var show_hint := GameState.gold < GameState.EGG_PRICE_GOLD
	var content_height := 3.0 * CARD_HEIGHT + 4.0 * CARD_GAP
	if show_hint:
		content_height += 92.0
	var content := Control.new()
	content.custom_minimum_size = Vector2(720, content_height)
	scroll.add_child(content)

	_add_egg_card(
		content,
		&"fire",
		FIRE_EGG_TEXTURE,
		"FIRE_EGG_NAME",
		Color("#d45b3f"),
		CARD_GAP
	)
	_add_egg_card(
		content,
		&"water",
		WATER_EGG_TEXTURE,
		"WATER_EGG_NAME",
		Color("#318eb7"),
		CARD_GAP + CARD_HEIGHT + CARD_GAP
	)
	_add_egg_card(
		content,
		&"earth",
		EARTH_EGG_TEXTURE,
		"EARTH_EGG_NAME",
		Color("#826143"),
		CARD_GAP + 2.0 * (CARD_HEIGHT + CARD_GAP)
	)

	if show_hint:
		var locked_hint := WidgetFactory.label(
			tr_text("EARN_COIN_HINT"),
			20,
			UiTokens.INK_SOFT,
			HORIZONTAL_ALIGNMENT_CENTER,
			UiTokens.FONT_REGULAR
		)
		locked_hint.position = Vector2(70, content_height - 94.0)
		locked_hint.size = Vector2(580, 70)
		locked_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(locked_hint)


func _build_header(top_y: float) -> void:
	var back := WidgetFactory.small_button(
		"‹",
		Rect2(28, top_y, 82, 82),
		UiTokens.CREAM
	)
	back.pressed.connect(navigate.bind("main", {}))
	add_child(back)

	var title := WidgetFactory.label(
		tr_text("SHOP_TITLE"),
		42,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_HEAVY
	)
	title.position = Vector2(120, top_y + 2.0)
	title.size = Vector2(480, 58)
	add_child(title)

	var instruction := WidgetFactory.label(
		tr_text("SHOP_INSTRUCTION"),
		21,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_REGULAR
	)
	instruction.position = Vector2(108, top_y + 61.0)
	instruction.size = Vector2(504, 74)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(instruction)


func _add_egg_card(
	parent: Control,
	kind: StringName,
	texture: Texture2D,
	name_key: String,
	accent: Color,
	y: float
) -> void:
	var card := Panel.new()
	card.position = Vector2(52, y)
	card.size = Vector2(616, CARD_HEIGHT)
	card.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(
			Color(1.0, 0.98, 0.93, 0.98),
			accent.darkened(0.18),
			28,
			7,
			Color(0.18, 0.12, 0.19, 0.24)
		)
	)
	parent.add_child(card)

	var egg_back := Panel.new()
	egg_back.position = Vector2(18, 18)
	egg_back.size = Vector2(210, 232)
	egg_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	egg_back.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(
			Color(accent.lightened(0.68), 0.52),
			Color(accent, 0.16),
			24,
			0
		)
	)
	card.add_child(egg_back)

	var egg := WidgetFactory.texture_rect(
		texture,
		Rect2(26, 10, 158, 210),
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	egg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	egg_back.add_child(egg)

	var item_name := WidgetFactory.label(
		tr_text(name_key),
		30,
		accent.darkened(0.12),
		HORIZONTAL_ALIGNMENT_LEFT,
		UiTokens.FONT_HEAVY
	)
	item_name.position = Vector2(258, 24)
	item_name.size = Vector2(326, 48)
	item_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(item_name)

	var price := WidgetFactory.label(
		tr_text("EGG_PRICE"),
		23,
		UiTokens.GOLD_DARK,
		HORIZONTAL_ALIGNMENT_LEFT,
		UiTokens.FONT_BOLD
	)
	price.position = Vector2(258, 77)
	price.size = Vector2(326, 40)
	card.add_child(price)

	var available := GameState.is_shop_egg_available(String(kind))
	var buy := WidgetFactory.button(
		tr_text("BUY_EGG") if available else tr_text("EGG_ALREADY_OWNED"),
		Rect2(252, 148, 338, 82),
		accent,
		accent.darkened(0.30)
	)
	buy.add_theme_font_size_override("font_size", 25)
	buy.disabled = not GameState.can_purchase_egg(String(kind))
	buy.pressed.connect(navigate.bind("purchase_egg", {"kind": String(kind)}))
	card.add_child(buy)
