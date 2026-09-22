extends SceneTree

const SHORT_PHONE_SIZE := Vector2(720, 1280)
const DYNAMIC_ISLAND_INSET := 122.0
const HOME_INDICATOR_INSET := 64.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var localization := root.get_node("Localization")
	var game_state := root.get_node("GameState")
	game_state.reset_for_tests()
	assert(localization.get_locale() == "de", "German must be the default locale.")

	_assert_screen_inside_safe_area("res://scenes/screens/main_menu_screen.tscn")
	_assert_screen_inside_safe_area("res://scenes/screens/shop_screen.tscn")
	_assert_shared_panel_styles()

	print("UI safe-area test: valid")
	quit()


func _assert_shared_panel_styles() -> void:
	var cream := WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.INK, 22, 8) as StyleBoxTexture
	assert(cream != null, "Card-sized panels must use comic texture frames.")
	assert(cream.texture != null, "Cream panel art must load.")
	assert(cream.get_meta("ui_panel_variant", "") == "cream", "Ink-bordered cards use cream art.")
	assert(cream.get_meta("ui_panel_raised", false), "Large shadow requests use raised panel art.")

	var selected := WidgetFactory.panel_style(UiTokens.CREAM, UiTokens.PINK_DARK, 20, 7)
	assert(
		selected.get_meta("ui_panel_variant", "") == "cream_pink",
		"Selected cards must keep their pink accent frame."
	)
	var dark := WidgetFactory.panel_style(Color("#382b3d"), UiTokens.INK, 12, 3)
	assert(dark.get_meta("ui_panel_variant", "") == "dark", "Instruction panels use dark art.")

	var compact := WidgetFactory.panel_style(Color("#e3d4b8"), UiTokens.INK, 8, 0)
	assert(compact is StyleBoxFlat, "Progress bars use rounded geometry at compact sizes.")


func _assert_screen_inside_safe_area(scene_path: String) -> void:
	var scene: PackedScene = load(scene_path)
	assert(scene != null, "The UI scene must load: %s" % scene_path)
	var screen := scene.instantiate() as GameScreen
	assert(screen != null, "The UI scene must instantiate: %s" % scene_path)
	screen.configure({
		"canvas_size": SHORT_PHONE_SIZE,
		"safe_top_inset": DYNAMIC_ISLAND_INSET,
		"safe_bottom_inset": HOME_INDICATOR_INSET,
	})
	root.add_child(screen)
	screen.build()

	var buttons: Array[Button] = []
	_collect_buttons(screen, buttons)
	assert(not buttons.is_empty(), "The tested screen must contain controls.")
	for button in buttons:
		var rect := button.get_global_rect()
		assert(
			rect.position.y >= DYNAMIC_ISLAND_INSET,
			"A button must not enter the Dynamic Island safe area."
		)
		assert(
			rect.end.y <= SHORT_PHONE_SIZE.y - HOME_INDICATOR_INSET,
			"A button must not enter the home-indicator safe area."
		)
		_assert_comic_button_style(button)

	screen.queue_free()


func _assert_comic_button_style(button: Button) -> void:
	var normal_style := button.get_theme_stylebox("normal")
	var pressed_style := button.get_theme_stylebox("pressed")
	assert(normal_style is StyleBoxTexture, "Buttons must use comic texture frames.")
	assert(pressed_style is StyleBoxTexture, "Pressed buttons must use comic texture frames.")
	assert(normal_style.texture != null, "Normal button art must load.")
	assert(pressed_style.texture != null, "Pressed button art must load.")
	assert(normal_style.texture != pressed_style.texture, "Pressed buttons need a distinct frame.")
	assert(
		button.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
		"Comic buttons must use smooth linear filtering."
	)
	if button.get_meta("ui_small_button_kind", "") == "back":
		assert(button.text.is_empty(), "Back buttons must not render a font chevron.")
		var chevron := button.get_node_or_null("PixelChevron") as Control
		assert(chevron != null, "Back buttons must use the shared comic chevron.")
		assert(
			chevron.size == button.size - Vector2(0, 9),
			"The comic chevron must center within the shadow-free button face."
		)
	elif button.get_meta("ui_small_button_kind", "") == "settings":
		assert(button.text.is_empty(), "Settings buttons must not render a font gear.")
		var gear := button.get_node_or_null("PixelGear") as Control
		assert(gear != null, "Settings buttons must use the shared comic gear.")
		assert(gear is TextureRect, "The settings gear must use the approved style-sheet sprite.")
		assert((gear as TextureRect).texture != null, "The settings gear texture must load.")
		assert(
			gear.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
			"The settings gear must preserve smooth illustrated edges."
		)
		assert(
			(gear.position + gear.size * 0.5).distance_to(
				(button.size - Vector2(0, 9)) * 0.5
			) <= 0.75,
			"The comic gear must center within the shadow-free button face."
		)


func _collect_buttons(node: Node, result: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button:
			result.append(child)
		_collect_buttons(child, result)
