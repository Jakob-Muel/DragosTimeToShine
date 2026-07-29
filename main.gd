extends Control

const PINK := Color("#f45b9d")
const PINK_DARK := Color("#b83372")
const CREAM := Color("#fff1c9")
const SKY := Color("#70d6f2")
const MINT := Color("#a8e57b")
const GREEN := Color("#49a85b")
const INK := Color("#2f2140")
const INK_SOFT := Color("#5c426a")
const WHITE := Color("#fffaf0")
const GOLD := Color("#ffc857")

const DRAGON_TEXTURE := preload("res://assets/art/dragon_pink_hd.png")
const ISLAND_TEXTURE := preload("res://assets/art/dragon_island_hd.png")
const ICE_DRAGON_TEXTURE := preload("res://assets/art/ice/ice_dragon_hd.png")
const ICE_EGG_TEXTURE := preload("res://assets/art/ice/ice_egg.png")
const ICE_ISLAND_TEXTURE := preload("res://assets/art/ice/ice_island_hd.png")
const FONT_REGULAR := preload("res://assets/fonts/PixelifySans-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/PixelifySans-Bold.ttf")
const BUILD_INFO := preload("res://scripts/build_info.gd")
const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const FLIGHT_GAME := preload("res://scripts/ui/flight_game.gd")
const FLIGHT_DRAGON_TEXTURE := preload("res://assets/art/flight/flight_dragon.png")

const DESIGN_WIDTH := 720.0
const BASE_DESIGN_HEIGHT := 1565.373
const DRAGON_FOOT_ANCHOR := Vector2(105.0, 218.0)
const GROOM_CLEAN_PER_PIXEL := 0.008

var screen_layer: Control
var canvas_size := Vector2(DESIGN_WIDTH, BASE_DESIGN_HEIGHT)
var layout_ready := false
var layout_rebuild_queued := false
var current_screen := "main"
var dragon_actor: Control
var dragon_sprite: TextureRect
var dragon_shadow: Control
var feed_button: Button
var hunger_bar: ProgressBar
var hunger_label: Label
var clean_bar: ProgressBar
var clean_label: Label
var care_label: Label
var groom_button: Button
var groom_area: Control
var groom_sprite: TextureRect
var groom_comb: Control
var groom_complete_label: Label
var dragon_alpha_image: Image
var active_dragon_texture: Texture2D = DRAGON_TEXTURE
var groom_stretch_target := Vector2.ONE
var groom_rotation_target := 0.0
var groom_drag_accumulator := Vector2.ZERO
var groom_completion_started := false
var groom_completion_tween: Tween
var selected_accessories := {
	"hat": false,
	"sword": false,
	"shield": false,
	"bowtie": false,
	"tie": false,
}
var accessory_positions := {
	"hat": Vector2(240, 100),
	"sword": Vector2(455, 210),
	"shield": Vector2(115, 350),
	"bowtie": Vector2(254, 330),
	"tie": Vector2(270, 380),
}
var accessory_nodes: Dictionary = {}
var accessory_buttons: Dictionary = {}
var competition_drag_area: Control
var dragged_accessory_kind := ""
var accessory_drag_offset := Vector2.ZERO
var accessory_z_counter := 100
var competition_result_overlay: Control
var competition_result_tween: Tween
var flight_score_label: Label
var flight_distance_label: Label
var flight_contest_tween: Tween
var flight_run_start_level := 0
var current_egg_id := ""
var step_error_message := ""
var selected_dragon_id := "luma"
var walking := false
var grooming := false
var bob_time := 0.0
var hunger: int:
	get:
		return GameState.hunger
	set(value):
		GameState.hunger = clampi(value, 0, 100)
var cleanliness: float:
	get:
		return GameState.cleanliness
	set(value):
		GameState.cleanliness = clampf(value, 0.0, 100.0)
var care_points: int:
	get:
		return GameState.care_points
	set(value):
		GameState.care_points = maxi(0, value)
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	dragon_alpha_image = DRAGON_TEXTURE.get_image()
	var game_theme := Theme.new()
	game_theme.default_font = FONT_REGULAR
	game_theme.default_font_size = 28
	theme = game_theme
	screen_layer = Control.new()
	add_child(screen_layer)
	_fit_design_canvas()
	Localization.locale_changed.connect(_on_locale_changed)
	StepCounter.steps_ready.connect(_on_steps_ready)
	StepCounter.permission_changed.connect(_on_step_permission_changed)
	StepCounter.step_error.connect(_on_step_error)
	_show_main_menu()
	layout_ready = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(screen_layer):
		var layout_changed := _fit_design_canvas()
		if layout_changed and layout_ready and not layout_rebuild_queued:
			layout_rebuild_queued = true
			call_deferred("_apply_responsive_rebuild")


func _fit_design_canvas() -> bool:
	if size.x <= 0.0 or size.y <= 0.0:
		return false
	var width_scale := size.x / DESIGN_WIDTH
	var responsive_height := size.y / width_scale
	var changed := absf(responsive_height - canvas_size.y) > 0.5
	canvas_size = Vector2(DESIGN_WIDTH, responsive_height)
	screen_layer.size = canvas_size
	screen_layer.scale = Vector2.ONE * width_scale
	screen_layer.position = Vector2.ZERO
	return changed


func _apply_responsive_rebuild() -> void:
	layout_rebuild_queued = false
	_rebuild_current_screen()


func _island_vertical_offset() -> float:
	return clampf((canvas_size.y - 1280.0) * 0.5, 0.0, 180.0)


func _safe_top_y(base_y: float = 32.0) -> float:
	if OS.get_name() not in ["iOS", "Android"]:
		return base_y
	var safe_area := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe_area.position.y <= 0 or window_size.x <= 0:
		return maxf(base_y, 104.0 if OS.get_name() == "iOS" else 64.0)
	var safe_top_in_design_units := float(safe_area.position.y) * DESIGN_WIDTH / float(window_size.x)
	return maxf(base_y, safe_top_in_design_units + 18.0)


func _process(delta: float) -> void:
	if current_screen == "groom" and is_instance_valid(groom_sprite):
		var response_speed := 13.0 if grooming else 7.5
		var response: float = 1.0 - exp(-response_speed * delta)
		var desired_scale := groom_stretch_target if grooming else Vector2.ONE
		var desired_rotation := groom_rotation_target if grooming else 0.0
		groom_sprite.scale = groom_sprite.scale.lerp(desired_scale, response)
		groom_sprite.rotation = lerpf(groom_sprite.rotation, desired_rotation, response)
		if not grooming:
			groom_stretch_target = groom_stretch_target.lerp(Vector2.ONE, response)
			groom_rotation_target = lerpf(groom_rotation_target, 0.0, response)
		return
	if current_screen != "habitat" or not is_instance_valid(dragon_sprite):
		return
	bob_time += delta
	var amplitude := 11.0 if walking else 4.0
	var speed := 13.0 if walking else 3.2
	var bounce: float = abs(sin(bob_time * speed)) * amplitude
	dragon_sprite.position.y = -bounce
	if is_instance_valid(dragon_shadow):
		dragon_shadow.squish = 1.0 - bounce / 55.0


func _clear_screen() -> void:
	walking = false
	grooming = false
	groom_completion_started = false
	groom_stretch_target = Vector2.ONE
	groom_rotation_target = 0.0
	groom_drag_accumulator = Vector2.ZERO
	if groom_completion_tween != null and groom_completion_tween.is_valid():
		groom_completion_tween.kill()
	groom_completion_tween = null
	for child in screen_layer.get_children():
		child.queue_free()
	dragon_actor = null
	dragon_sprite = null
	dragon_shadow = null
	feed_button = null
	groom_button = null
	hunger_bar = null
	hunger_label = null
	clean_bar = null
	clean_label = null
	care_label = null
	groom_area = null
	groom_sprite = null
	groom_comb = null
	groom_complete_label = null
	accessory_nodes.clear()
	accessory_buttons.clear()
	competition_drag_area = null
	dragged_accessory_kind = ""
	accessory_drag_offset = Vector2.ZERO
	accessory_z_counter = 100
	competition_result_overlay = null
	if competition_result_tween != null and competition_result_tween.is_valid():
		competition_result_tween.kill()
	competition_result_tween = null
	flight_score_label = null
	flight_distance_label = null
	if flight_contest_tween != null and flight_contest_tween.is_valid():
		flight_contest_tween.kill()
	flight_contest_tween = null


func _show_main_menu() -> void:
	_clear_screen()
	current_screen = "main"
	var top_shift := _safe_top_y(38.0) - 38.0
	var sky_fill := ColorRect.new()
	sky_fill.position = Vector2.ZERO
	sky_fill.size = canvas_size
	sky_fill.color = SKY
	screen_layer.add_child(sky_fill)
	var background := _texture_rect(ISLAND_TEXTURE, Rect2(0, 0, canvas_size.x, canvas_size.y), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	screen_layer.add_child(background)
	var wash := ColorRect.new()
	wash.position = Vector2.ZERO
	wash.size = canvas_size
	wash.color = Color(0.42, 0.84, 0.96, 0.24)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(wash)

	_add_resource_pill(Vector2(38, 38 + top_shift), GameState.gems, "gem", PINK)
	_add_resource_pill(Vector2(510, 38 + top_shift), GameState.gold, "coin", GOLD)
	var language_button := _small_button(Localization.get_locale().to_upper(), Rect2(300, 38 + top_shift, 120, 62), CREAM)
	language_button.add_theme_font_size_override("font_size", 24)
	language_button.pressed.connect(Localization.cycle_locale)
	screen_layer.add_child(language_button)

	var title_shadow := _label(_t("BRAND_NAME"), 82, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title_shadow.position = Vector2(3, 145 + top_shift)
	title_shadow.size = Vector2(720, 105)
	screen_layer.add_child(title_shadow)
	var title := _label(_t("BRAND_NAME"), 82, PINK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(0, 138 + top_shift)
	title.size = Vector2(720, 105)
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 8)
	screen_layer.add_child(title)

	var ribbon := Panel.new()
	ribbon.position = Vector2(160, 240 + top_shift)
	ribbon.size = Vector2(400, 70)
	ribbon.add_theme_stylebox_override("panel", _panel_style(CREAM, INK, 14, 6))
	screen_layer.add_child(ribbon)
	var subtitle := _label(_t("BRAND_SUBTITLE"), 33, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	ribbon.add_child(subtitle)

	var dragon := _texture_rect(DRAGON_TEXTURE, Rect2(178, 312 + top_shift, 364, 318), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	screen_layer.add_child(dragon)

	var prompt_panel := Panel.new()
	prompt_panel.position = Vector2(42, 635 + top_shift)
	prompt_panel.size = Vector2(636, 91)
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.93), INK, 18, 5))
	screen_layer.add_child(prompt_panel)
	var greeting := _label(_t("MAIN_GREETING"), 27, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	greeting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	prompt_panel.add_child(greeting)

	var den_button := _button(_t("NAV_DEN"), Rect2(72, 820, 576, 118), PINK, PINK_DARK)
	den_button.pressed.connect(_show_den)
	screen_layer.add_child(den_button)
	_add_button_caption(den_button, _t("NAV_DEN_CAPTION"))

	var shop_button := _button(_t("NAV_SHOP"), Rect2(72, 972, 276, 118), Color("#8ed5aa"), Color("#4d9a70"))
	shop_button.pressed.connect(_show_shop)
	screen_layer.add_child(shop_button)
	_add_button_caption(shop_button, _t("SHOP_CAPTION"))

	var contest_button := _button(_t("NAV_CONTEST"), Rect2(372, 972, 276, 118), GOLD, Color("#d38a38"))
	contest_button.pressed.connect(_show_competition)
	screen_layer.add_child(contest_button)
	_add_button_caption(contest_button, _t("CONTEST_CAPTION"))

	var footer := _label(_t("FOOTER"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	footer.position = Vector2(0, canvas_size.y - 112)
	footer.size = Vector2(720, 40)
	screen_layer.add_child(footer)
	var version := _label(BUILD_INFO.VERSION, 18, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	version.position = Vector2(0, canvas_size.y - 72)
	version.size = Vector2(720, 30)
	screen_layer.add_child(version)


func _show_den() -> void:
	_clear_screen()
	current_screen = "den"
	var top_shift := _safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)

	var back := _small_button("‹", Rect2(32, 44 + top_shift, 78, 72), CREAM)
	back.pressed.connect(_show_main_menu)
	screen_layer.add_child(back)

	var title := _label(_t("DEN_TITLE"), 47, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	screen_layer.add_child(title)

	var info := Panel.new()
	info.position = Vector2(40, 168 + top_shift)
	info.size = Vector2(640, 90)
	info.add_theme_stylebox_override("panel", _panel_style(Color("#fff1c9"), INK, 14, 5))
	screen_layer.add_child(info)
	var info_text := _label(_t("DEN_HUB_INSTRUCTION"), 27, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	info_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	info.add_child(info_text)

	var dragons_button := _button(
		_t("DEN_DRAGONS"),
		Rect2(72, 320 + top_shift, 576, 168),
		PINK,
		PINK_DARK
	)
	dragons_button.pressed.connect(_show_dragons)
	screen_layer.add_child(dragons_button)
	_add_button_caption(dragons_button, _t("DEN_DRAGONS_CAPTION", {"count": GameState.dragons.size()}))

	var eggs_button := _button(
		_t("DEN_EGGS"),
		Rect2(72, 530 + top_shift, 576, 168),
		GOLD,
		Color("#d38a38")
	)
	eggs_button.pressed.connect(_show_eggs)
	screen_layer.add_child(eggs_button)
	_add_button_caption(eggs_button, _t("DEN_EGGS_CAPTION", {"count": GameState.eggs.size()}))

	var shop_button := _button(_t("NAV_SHOP"), Rect2(120, 770 + top_shift, 480, 112), Color("#8ed5aa"), Color("#4d9a70"))
	shop_button.pressed.connect(_show_shop)
	screen_layer.add_child(shop_button)
	_add_button_caption(shop_button, _t("SHOP_CAPTION"))


func _show_dragons() -> void:
	_clear_screen()
	current_screen = "dragons"
	var top_shift := _safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)

	var back := _small_button("‹", Rect2(32, 44 + top_shift, 78, 72), CREAM)
	back.pressed.connect(_show_den)
	screen_layer.add_child(back)
	var title := _label(_t("DEN_DRAGONS"), 47, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	screen_layer.add_child(title)
	var count := _label(
		_t("DEN_COUNT", {"owned": GameState.dragons.size(), "capacity": GameState.DRAGON_CAPACITY}),
		22,
		INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	count.position = Vector2(0, 130 + top_shift)
	count.size = Vector2(720, 34)
	screen_layer.add_child(count)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 174 + top_shift)
	scroll.size = Vector2(720, maxf(420.0, canvas_size.y - 174.0 - top_shift))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	screen_layer.add_child(scroll)
	var content := Control.new()
	var dragon_rows := ceili(GameState.dragons.size() / 2.0)
	content.custom_minimum_size = Vector2(720, maxf(580.0, 142.0 + dragon_rows * 450.0))
	scroll.add_child(content)

	var info := Panel.new()
	info.position = Vector2(40, 10)
	info.size = Vector2(640, 84)
	info.add_theme_stylebox_override("panel", _panel_style(CREAM, INK, 14, 5))
	content.add_child(info)
	var info_text := _label(_t("DEN_INSTRUCTION"), 25, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	info_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	info.add_child(info_text)

	var dragon_count := GameState.dragons.size()
	var card_width := 624.0 if dragon_count == 1 else 300.0
	for index in dragon_count:
		var dragon_data: Dictionary = GameState.dragons[index]
		var is_ice_dragon := String(dragon_data.get("species", "sunwing")) == "ice"
		var column := index % 2
		var row := index / 2
		var card_x := 48.0 if dragon_count == 1 else 42.0 + column * 330.0
		var card_y := 128.0 + row * 450.0
		var card := Button.new()
		card.position = Vector2(card_x, card_y)
		card.size = Vector2(card_width, 410)
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.add_theme_stylebox_override("normal", _panel_style(WHITE, INK, 20, 8))
		card.add_theme_stylebox_override("hover", _panel_style(Color("#fff9de"), PINK_DARK, 20, 8))
		card.add_theme_stylebox_override("pressed", _panel_style(CREAM, PINK_DARK, 20, 3))
		card.pressed.connect(_select_dragon.bind(String(dragon_data.get("id", "luma"))))
		content.add_child(card)

		var portrait_back := Panel.new()
		portrait_back.position = Vector2(20, 22)
		portrait_back.size = Vector2(card_width - 40.0, 245)
		portrait_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_back.add_theme_stylebox_override(
			"panel",
			_panel_style(Color("#dff8ff") if is_ice_dragon else Color("#bdeaf7"), INK, 16, 3)
		)
		card.add_child(portrait_back)
		var portrait := _texture_rect(
			_dragon_texture_for(dragon_data),
			Rect2(20, 5, portrait_back.size.x - 40.0, 230),
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if is_ice_dragon else CanvasItem.TEXTURE_FILTER_LINEAR
		portrait_back.add_child(portrait)
		var dragon_name := _label(
			_t(String(dragon_data.get("name_key", "DRAGON_NAME"))),
			42 if dragon_count == 1 else 34,
			Color("#3187b8") if is_ice_dragon else PINK_DARK,
			HORIZONTAL_ALIGNMENT_CENTER,
			FONT_BOLD
		)
		dragon_name.position = Vector2(12, 278)
		dragon_name.size = Vector2(card_width - 24.0, 54)
		card.add_child(dragon_name)
		var visit := _label(_t("VISIT_ISLAND"), 23, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
		visit.position = Vector2(10, 342)
		visit.size = Vector2(card_width - 20.0, 40)
		card.add_child(visit)


func _select_dragon(dragon_id: String) -> void:
	selected_dragon_id = dragon_id
	_show_habitat()


func _selected_dragon_name() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("id", "")) == selected_dragon_id:
			return _t(String(dragon.get("name_key", "DRAGON_NAME")))
	return _t("DRAGON_NAME")


func _selected_dragon_data() -> Dictionary:
	return GameState.get_dragon(selected_dragon_id)


func _dragon_texture_for(dragon_data: Dictionary) -> Texture2D:
	return ICE_DRAGON_TEXTURE if String(dragon_data.get("species", "sunwing")) == "ice" else DRAGON_TEXTURE


func _selected_dragon_texture() -> Texture2D:
	return _dragon_texture_for(_selected_dragon_data())


func _egg_name_key(egg: Dictionary) -> String:
	return "ICE_EGG_NAME" if String(egg.get("kind", "sunwing")) == "ice" else "EGG_NAME"


func _add_egg_art(parent: Control, egg: Dictionary, rect: Rect2) -> Control:
	if String(egg.get("kind", "sunwing")) == "ice":
		var ice_egg := _texture_rect(ICE_EGG_TEXTURE, rect, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		ice_egg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(ice_egg)
		return ice_egg
	var sunwing_egg := PIXEL_ART.PixelEgg.new()
	sunwing_egg.position = rect.position
	sunwing_egg.size = rect.size
	parent.add_child(sunwing_egg)
	return sunwing_egg


func _show_eggs() -> void:
	_clear_screen()
	current_screen = "eggs"
	var top_shift := _safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var back := _small_button("‹", Rect2(32, 44 + top_shift, 78, 72), CREAM)
	back.pressed.connect(_show_den)
	screen_layer.add_child(back)
	var title := _label(_t("EGGS_TITLE"), 47, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	screen_layer.add_child(title)
	var count := _label(_t("EGG_COUNT", {"count": GameState.eggs.size()}), 22, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	count.position = Vector2(0, 130 + top_shift)
	count.size = Vector2(720, 34)
	screen_layer.add_child(count)

	if GameState.eggs.is_empty():
		var empty_panel := Panel.new()
		empty_panel.position = Vector2(60, 250 + top_shift)
		empty_panel.size = Vector2(600, 300)
		empty_panel.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 20, 7))
		screen_layer.add_child(empty_panel)
		var empty_text := _label(_t("NO_EGGS"), 32, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
		empty_text.position = Vector2(30, 45)
		empty_text.size = Vector2(540, 60)
		empty_panel.add_child(empty_text)
		var hint := _label(_t("FIND_EGG_IN_SHOP"), 24, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
		hint.position = Vector2(45, 120)
		hint.size = Vector2(510, 75)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_panel.add_child(hint)
		var shop := _button(_t("NAV_SHOP"), Rect2(80, 620 + top_shift, 560, 110), Color("#8ed5aa"), Color("#4d9a70"))
		shop.pressed.connect(_show_shop)
		screen_layer.add_child(shop)
		return

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 185 + top_shift)
	scroll.size = Vector2(720, maxf(420.0, canvas_size.y - 185.0 - top_shift))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	screen_layer.add_child(scroll)
	var content := Control.new()
	content.custom_minimum_size = Vector2(720, maxf(520.0, 42.0 + GameState.eggs.size() * 238.0))
	scroll.add_child(content)

	for index in GameState.eggs.size():
		var egg: Dictionary = GameState.eggs[index]
		var card := Button.new()
		card.position = Vector2(48, 22 + index * 238)
		card.size = Vector2(624, 210)
		card.focus_mode = Control.FOCUS_NONE
		card.add_theme_stylebox_override("normal", _panel_style(WHITE, INK, 20, 7))
		card.add_theme_stylebox_override("hover", _panel_style(CREAM, PINK_DARK, 20, 7))
		card.add_theme_stylebox_override("pressed", _panel_style(CREAM, PINK_DARK, 20, 3))
		card.pressed.connect(_show_egg_detail.bind(String(egg.get("id", ""))))
		content.add_child(card)
		_add_egg_art(card, egg, Rect2(25, 18, 130, 170))
		var egg_name := _label(
			_t(_egg_name_key(egg)),
			34,
			Color("#3187b8") if String(egg.get("kind", "sunwing")) == "ice" else PINK_DARK,
			HORIZONTAL_ALIGNMENT_LEFT,
			FONT_BOLD
		)
		egg_name.position = Vector2(180, 28)
		egg_name.size = Vector2(405, 52)
		card.add_child(egg_name)
		var progress := int(egg.get("progress_steps", 0))
		var required := int(egg.get("required_steps", GameState.EGG_REQUIRED_STEPS))
		var progress_text := _label(
			_t("EGG_NOT_STARTED") if int(egg.get("incubation_start", 0)) == 0 else _t("EGG_STEP_PROGRESS", {"current": progress, "required": required}),
			22,
			INK_SOFT,
			HORIZONTAL_ALIGNMENT_LEFT,
			FONT_BOLD
		)
		progress_text.position = Vector2(180, 88)
		progress_text.size = Vector2(405, 76)
		progress_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(progress_text)


func _show_egg_detail(egg_id: String, query_steps: bool = true) -> void:
	var egg := GameState.get_egg(egg_id)
	if egg.is_empty():
		_show_eggs()
		return
	_clear_screen()
	current_screen = "egg_detail"
	current_egg_id = egg_id
	var top_shift := _safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var back := _small_button("‹", Rect2(32, 44 + top_shift, 78, 72), CREAM)
	back.pressed.connect(_show_eggs)
	screen_layer.add_child(back)
	var title := _label(_t("EGG_DETAIL_TITLE"), 43, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	screen_layer.add_child(title)

	var egg_panel := Panel.new()
	egg_panel.position = Vector2(70, 170 + top_shift)
	egg_panel.size = Vector2(580, 620)
	egg_panel.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 24, 9))
	screen_layer.add_child(egg_panel)
	_add_egg_art(egg_panel, egg, Rect2(165, 35, 250, 330))
	var egg_name := _label(
		_t(_egg_name_key(egg)),
		38,
		Color("#3187b8") if String(egg.get("kind", "sunwing")) == "ice" else PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	egg_name.position = Vector2(30, 372)
	egg_name.size = Vector2(520, 55)
	egg_panel.add_child(egg_name)

	var progress := int(egg.get("progress_steps", 0))
	var required := int(egg.get("required_steps", GameState.EGG_REQUIRED_STEPS))
	var progress_label := _label(
		_t("EGG_STEP_PROGRESS", {"current": progress, "required": required}),
		25,
		INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	progress_label.position = Vector2(30, 438)
	progress_label.size = Vector2(520, 42)
	egg_panel.add_child(progress_label)
	var progress_bar := ProgressBar.new()
	progress_bar.position = Vector2(45, 496)
	progress_bar.size = Vector2(490, 38)
	progress_bar.max_value = required
	progress_bar.value = progress
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _panel_style(Color("#e3d4b8"), INK, 8, 0))
	progress_bar.add_theme_stylebox_override("fill", _panel_style(GOLD, INK, 8, 0))
	egg_panel.add_child(progress_bar)
	var provider := _label(
		_t("STEP_PROVIDER", {"provider": _t("STEP_PROVIDER_%s" % StepCounter.provider_name().to_upper())}),
		19,
		INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	provider.position = Vector2(30, 548)
	provider.size = Vector2(520, 32)
	egg_panel.add_child(provider)
	if not step_error_message.is_empty():
		var error_label := _label(_step_error_text(step_error_message), 17, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
		error_label.position = Vector2(80, 786 + top_shift)
		error_label.size = Vector2(560, 68)
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		screen_layer.add_child(error_label)

	var action_y := 860.0 if not step_error_message.is_empty() else 840.0
	var incubation_start := int(egg.get("incubation_start", 0))
	if incubation_start == 0:
		var start := _button(_t("START_HATCHING"), Rect2(110, action_y + top_shift, 500, 110), PINK, PINK_DARK)
		start.pressed.connect(_start_current_egg)
		screen_layer.add_child(start)
	elif GameState.can_hatch(egg_id):
		var hatch := _button(_t("HATCH_NOW"), Rect2(110, action_y + top_shift, 500, 110), PINK, PINK_DARK)
		hatch.pressed.connect(_hatch_current_egg)
		screen_layer.add_child(hatch)
	elif StepCounter.is_mock():
		var test_steps := _button(_t("ADD_TEST_STEPS"), Rect2(110, action_y + top_shift, 500, 110), Color("#8ed5aa"), Color("#4d9a70"))
		test_steps.pressed.connect(_add_test_steps)
		screen_layer.add_child(test_steps)
	elif not StepCounter.has_permission():
		var permission := _button(_t("STEP_PERMISSION"), Rect2(110, action_y + top_shift, 500, 110), PINK, PINK_DARK)
		permission.pressed.connect(StepCounter.request_permission)
		screen_layer.add_child(permission)
	else:
		var refresh := _button(_t("REFRESH_STEPS"), Rect2(110, action_y + top_shift, 500, 110), Color("#8ed5aa"), Color("#4d9a70"))
		refresh.pressed.connect(_refresh_current_egg_steps)
		screen_layer.add_child(refresh)

	if query_steps and incubation_start > 0 and (StepCounter.is_mock() or StepCounter.has_permission()):
		call_deferred("_refresh_current_egg_steps")


func _start_current_egg() -> void:
	GameState.start_incubation(current_egg_id, StepCounter.get_mock_total_steps())
	if not StepCounter.is_mock() and not StepCounter.has_permission():
		StepCounter.request_permission()
	_show_egg_detail(current_egg_id)


func _refresh_current_egg_steps() -> void:
	var egg := GameState.get_egg(current_egg_id)
	if egg.is_empty() or int(egg.get("incubation_start", 0)) == 0:
		return
	step_error_message = ""
	StepCounter.query_steps_since(
		int(egg.get("incubation_start", 0)),
		int(egg.get("mock_baseline", 0))
	)


func _add_test_steps() -> void:
	StepCounter.add_mock_steps(250)
	_refresh_current_egg_steps()


func _on_steps_ready(start_unix: int, steps: int) -> void:
	if current_egg_id.is_empty():
		return
	var egg := GameState.get_egg(current_egg_id)
	if egg.is_empty() or int(egg.get("incubation_start", 0)) != start_unix:
		return
	GameState.update_egg_progress(current_egg_id, steps)
	if current_screen == "egg_detail":
		_show_egg_detail(current_egg_id, false)


func _on_step_permission_changed(granted: bool) -> void:
	if granted and current_screen == "egg_detail":
		_refresh_current_egg_steps()


func _on_step_error(message: String) -> void:
	push_warning("Step counter: %s" % message)
	step_error_message = message
	if current_screen == "egg_detail":
		_show_egg_detail(current_egg_id, false)


func _step_error_text(message: String) -> String:
	if "entitlement" in message.to_lower():
		return _t("STEP_ERROR_ENTITLEMENT")
	return _t("STEP_ERROR_WITH_DETAIL", {"detail": message})


func _hatch_current_egg() -> void:
	var egg_kind := String(GameState.get_egg(current_egg_id).get("kind", "sunwing"))
	if not GameState.hatch_egg(current_egg_id):
		return
	var message := _label(
		_t("ICE_HATCHED_MESSAGE") if egg_kind == "ice" else _t("HATCHED_MESSAGE"),
		48,
		Color("#3187b8") if egg_kind == "ice" else PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	message.position = Vector2(45, canvas_size.y * 0.5 - 70)
	message.size = Vector2(630, 100)
	message.z_index = 3950
	message.add_theme_color_override("font_outline_color", WHITE)
	message.add_theme_constant_override("outline_size", 8)
	screen_layer.add_child(message)
	_burst_confetti(screen_layer, Vector2(canvas_size.x * 0.5, canvas_size.y * 0.48), 54, 3900)
	var hatch_tween := create_tween()
	hatch_tween.tween_interval(1.55)
	hatch_tween.tween_callback(_show_dragons)


func _show_shop() -> void:
	_clear_screen()
	current_screen = "shop"
	var top_shift := _safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var back := _small_button("‹", Rect2(32, 44 + top_shift, 78, 72), CREAM)
	back.pressed.connect(_show_main_menu)
	screen_layer.add_child(back)
	var title := _label(_t("SHOP_TITLE"), 47, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	screen_layer.add_child(title)
	var instruction := _label(_t("SHOP_INSTRUCTION"), 25, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	instruction.position = Vector2(50, 140 + top_shift)
	instruction.size = Vector2(620, 70)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_layer.add_child(instruction)
	var card := Panel.new()
	card.position = Vector2(70, 240 + top_shift)
	card.size = Vector2(580, 520)
	card.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 24, 9))
	screen_layer.add_child(card)
	_add_egg_art(card, {"kind": "ice"}, Rect2(180, 35, 220, 290))
	var item_name := _label(_t("ICE_EGG_NAME"), 37, Color("#3187b8"), HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	item_name.position = Vector2(25, 340)
	item_name.size = Vector2(530, 55)
	card.add_child(item_name)
	var price := _label(_t("EGG_PRICE"), 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	price.position = Vector2(25, 405)
	price.size = Vector2(530, 45)
	card.add_child(price)
	var get_egg := _button(_t("BUY_EGG"), Rect2(110, 820 + top_shift, 500, 112), PINK, PINK_DARK)
	get_egg.disabled = GameState.gold < GameState.EGG_PRICE_GOLD
	get_egg.pressed.connect(_purchase_egg)
	screen_layer.add_child(get_egg)
	if get_egg.disabled:
		var locked_hint := _label(_t("EARN_COIN_HINT"), 22, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
		locked_hint.position = Vector2(70, 955 + top_shift)
		locked_hint.size = Vector2(580, 60)
		locked_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		screen_layer.add_child(locked_hint)


func _purchase_egg() -> void:
	var egg_id := GameState.purchase_egg("ice")
	if not egg_id.is_empty():
		_show_egg_detail(egg_id, false)


func _show_habitat() -> void:
	_clear_screen()
	current_screen = "habitat"
	var top_shift := _safe_top_y(32.0) - 32.0
	bob_time = 0.0
	var dragon_data := _selected_dragon_data()
	var is_ice_dragon := String(dragon_data.get("species", "sunwing")) == "ice"
	active_dragon_texture = _dragon_texture_for(dragon_data)
	var sky_fill := ColorRect.new()
	sky_fill.position = Vector2.ZERO
	sky_fill.size = canvas_size
	sky_fill.color = Color("#bcecff") if is_ice_dragon else SKY
	screen_layer.add_child(sky_fill)
	var background := _texture_rect(
		ICE_ISLAND_TEXTURE if is_ice_dragon else ISLAND_TEXTURE,
		Rect2(0, 0, canvas_size.x, canvas_size.y),
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if is_ice_dragon else CanvasItem.TEXTURE_FILTER_LINEAR
	screen_layer.add_child(background)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, 32 + top_shift)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 2000
	top_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("#eefcff") if is_ice_dragon else Color(1, 0.98, 0.91, 0.94), INK, 18, 6)
	)
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_show_dragons)
	top_panel.add_child(back)
	var active_dragon_name := _selected_dragon_name()
	var name := _label(_t("DRAGON_ISLAND_TITLE", {"name": active_dragon_name}), 38, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	name.position = Vector2(92, 13)
	name.size = Vector2(470, 48)
	top_panel.add_child(name)
	var level := _label(
		_t("ICE_LEVEL_SPECIES") if is_ice_dragon else _t("LEVEL_SPECIES"),
		20,
		INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	level.position = Vector2(92, 59)
	level.size = Vector2(470, 28)
	top_panel.add_child(level)
	var hearts := _label("♥", 35, Color("#55bde8") if is_ice_dragon else PINK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	hearts.position = Vector2(580, 21)
	hearts.size = Vector2(65, 50)
	top_panel.add_child(hearts)

	var tip := Panel.new()
	tip.position = Vector2(116, 157 + top_shift)
	tip.size = Vector2(488, 62)
	tip.z_index = 2000
	tip.add_theme_stylebox_override("panel", _panel_style(Color(0.19, 0.13, 0.25, 0.88), INK, 12, 3))
	screen_layer.add_child(tip)
	var tip_text := _label(_t("HABITAT_TIP_DYNAMIC", {"name": active_dragon_name}), 23, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	tip_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	tip.add_child(tip_text)
	var tip_berry := PIXEL_ART.BerryPickup.new()
	tip_berry.position = Vector2(14, -2)
	tip_berry.size = Vector2(64, 64)
	tip_berry.scale = Vector2(0.72, 0.72)
	tip.add_child(tip_berry)

	dragon_actor = Control.new()
	dragon_actor.position = Vector2(255, 407 + _island_vertical_offset())
	dragon_actor.size = Vector2(250, 250)
	dragon_actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dragon_actor.z_index = 650
	screen_layer.add_child(dragon_actor)

	dragon_shadow = PIXEL_ART.BlobShadow.new()
	dragon_shadow.position = Vector2(30, 199)
	dragon_shadow.size = Vector2(150, 38)
	dragon_actor.add_child(dragon_shadow)

	dragon_sprite = _texture_rect(active_dragon_texture, Rect2(0, 0, 250, 224), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	dragon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if is_ice_dragon else CanvasItem.TEXTURE_FILTER_LINEAR
	dragon_sprite.pivot_offset = dragon_sprite.size / 2.0
	dragon_actor.add_child(dragon_sprite)

	var bottom := Panel.new()
	bottom.position = Vector2(24, canvas_size.y - 456)
	bottom.size = Vector2(672, 420)
	bottom.z_index = 2000
	bottom.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.97), INK, 22, 9))
	screen_layer.add_child(bottom)

	var mood_title := _label(_t("MOOD"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	mood_title.position = Vector2(26, 18)
	mood_title.size = Vector2(120, 30)
	bottom.add_child(mood_title)
	var mood := _label(_t("HAPPY_THREE"), 28, PINK_DARK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	mood.position = Vector2(350, 12)
	mood.size = Vector2(288, 40)
	bottom.add_child(mood)

	var hunger_title := _label(_t("HUNGER"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	hunger_title.position = Vector2(26, 64)
	hunger_title.size = Vector2(140, 30)
	bottom.add_child(hunger_title)
	hunger_label = _label("%d%%" % hunger, 21, INK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	hunger_label.position = Vector2(542, 64)
	hunger_label.size = Vector2(96, 30)
	bottom.add_child(hunger_label)
	hunger_bar = ProgressBar.new()
	hunger_bar.position = Vector2(26, 98)
	hunger_bar.size = Vector2(612, 32)
	hunger_bar.value = hunger
	hunger_bar.show_percentage = false
	hunger_bar.add_theme_stylebox_override("background", _panel_style(Color("#e3d4b8"), INK, 8, 0))
	hunger_bar.add_theme_stylebox_override("fill", _panel_style(GOLD, INK, 8, 0))
	bottom.add_child(hunger_bar)

	var clean_title := _label(_t("CLEAN"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	clean_title.position = Vector2(26, 145)
	clean_title.size = Vector2(140, 30)
	bottom.add_child(clean_title)
	clean_label = _label("%d%%" % floori(cleanliness), 21, INK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	clean_label.position = Vector2(542, 145)
	clean_label.size = Vector2(96, 30)
	bottom.add_child(clean_label)
	clean_bar = ProgressBar.new()
	clean_bar.position = Vector2(26, 179)
	clean_bar.size = Vector2(612, 32)
	clean_bar.value = cleanliness
	clean_bar.show_percentage = false
	clean_bar.add_theme_stylebox_override("background", _panel_style(Color("#e3d4b8"), INK, 8, 0))
	clean_bar.add_theme_stylebox_override("fill", _panel_style(MINT, INK, 8, 0))
	bottom.add_child(clean_bar)

	care_label = _label(_t("CARE_POINTS", {"value": care_points}), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	care_label.position = Vector2(26, 229)
	care_label.size = Vector2(270, 32)
	bottom.add_child(care_label)
	var inventory := _label(_t("SUNBERRIES"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	inventory.position = Vector2(350, 229)
	inventory.size = Vector2(288, 32)
	bottom.add_child(inventory)

	feed_button = _button(_t("FEED"), Rect2(26, 276, 294, 108), PINK, PINK_DARK)
	feed_button.pressed.connect(_feed_dragon)
	bottom.add_child(feed_button)
	_add_button_caption(feed_button, _t("FEED_CAPTION"))

	groom_button = _button(_t("GROOM"), Rect2(344, 276, 294, 108), Color("#8ed5aa"), Color("#4d9a70"))
	groom_button.pressed.connect(_show_grooming)
	bottom.add_child(groom_button)
	_add_button_caption(groom_button, _t("GROOM_CAPTION_DYNAMIC", {"name": active_dragon_name}))


func _show_grooming() -> void:
	_clear_screen()
	current_screen = "groom"
	var top_shift := _safe_top_y(32.0) - 32.0
	var dragon_data := _selected_dragon_data()
	var is_ice_dragon := String(dragon_data.get("species", "sunwing")) == "ice"
	active_dragon_texture = _dragon_texture_for(dragon_data)
	dragon_alpha_image = active_dragon_texture.get_image()
	var height_mix := clampf((canvas_size.y - 1280.0) / (BASE_DESIGN_HEIGHT - 1280.0), 0.0, 1.0)
	var portrait_height := lerpf(560.0, 738.0, height_mix)
	var sprite_height := portrait_height - 88.0
	var portrait_bottom := 398.0 + top_shift + portrait_height
	var hint_y := portrait_bottom + 20.0
	var complete_y := hint_y + 80.0
	var done_y := canvas_size.y - 142.0

	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var wash := ColorRect.new()
	wash.position = Vector2.ZERO
	wash.size = canvas_size
	wash.color = Color(0.66, 0.91, 1.0, 0.27) if is_ice_dragon else Color(1.0, 0.72, 0.84, 0.23)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(wash)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, 32 + top_shift)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.97), INK, 18, 6))
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_leave_grooming)
	top_panel.add_child(back)
	var active_dragon_name := _selected_dragon_name()
	var title := _label(_t("GROOM_TITLE_DYNAMIC", {"name": active_dragon_name}), 40, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(98, 14)
	title.size = Vector2(474, 70)
	top_panel.add_child(title)

	var progress_panel := Panel.new()
	progress_panel.position = Vector2(40, 164 + top_shift)
	progress_panel.size = Vector2(640, 118)
	progress_panel.z_index = 100
	progress_panel.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 16, 5))
	screen_layer.add_child(progress_panel)
	var clean_title := _label(_t("CLEAN"), 25, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	clean_title.position = Vector2(22, 14)
	clean_title.size = Vector2(180, 34)
	progress_panel.add_child(clean_title)
	clean_label = _label("%d%%" % floori(cleanliness), 25, PINK_DARK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	clean_label.position = Vector2(490, 14)
	clean_label.size = Vector2(120, 34)
	progress_panel.add_child(clean_label)
	clean_bar = ProgressBar.new()
	clean_bar.position = Vector2(22, 60)
	clean_bar.size = Vector2(596, 34)
	clean_bar.value = cleanliness
	clean_bar.show_percentage = false
	clean_bar.add_theme_stylebox_override("background", _panel_style(Color("#e3d4b8"), INK, 8, 0))
	clean_bar.add_theme_stylebox_override("fill", _panel_style(MINT, INK, 8, 0))
	progress_panel.add_child(clean_bar)

	var instruction := Panel.new()
	instruction.position = Vector2(82, 306 + top_shift)
	instruction.size = Vector2(556, 66)
	instruction.z_index = 100
	instruction.add_theme_stylebox_override("panel", _panel_style(Color(0.19, 0.13, 0.25, 0.92), INK, 12, 3))
	screen_layer.add_child(instruction)
	var instruction_text := _label(
		_t("GROOM_INSTRUCTION_DYNAMIC", {"name": active_dragon_name}),
		24,
		WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	instruction_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	instruction.add_child(instruction_text)

	var portrait_panel := Panel.new()
	portrait_panel.position = Vector2(40, 398 + top_shift)
	portrait_panel.size = Vector2(640, portrait_height)
	portrait_panel.clip_contents = true
	portrait_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("#dff8ff") if is_ice_dragon else Color("#bdeaf7"), INK, 22, 7)
	)
	screen_layer.add_child(portrait_panel)

	groom_sprite = _texture_rect(active_dragon_texture, Rect2(90, 420 + top_shift, 540, sprite_height), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	groom_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if is_ice_dragon else CanvasItem.TEXTURE_FILTER_LINEAR
	groom_sprite.pivot_offset = groom_sprite.size / 2.0
	groom_sprite.z_index = 20
	screen_layer.add_child(groom_sprite)

	groom_area = Control.new()
	groom_area.position = portrait_panel.position
	groom_area.size = portrait_panel.size
	groom_area.clip_contents = true
	groom_area.mouse_filter = Control.MOUSE_FILTER_STOP
	groom_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	groom_area.z_index = 30
	groom_area.gui_input.connect(_on_groom_input)
	screen_layer.add_child(groom_area)

	groom_comb = PIXEL_ART.PixelComb.new()
	groom_comb.position = Vector2(groom_area.size.x - 112.0, groom_area.size.y - 104.0)
	groom_comb.size = Vector2(96, 80)
	groom_comb.z_index = 1
	groom_area.add_child(groom_comb)

	var hint := _label(_t("GROOM_HINT"), 22, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	hint.position = Vector2(55, hint_y)
	hint.size = Vector2(610, 74)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_layer.add_child(hint)

	groom_complete_label = _label(_t("SPARKLING_CLEAN"), 28, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	groom_complete_label.position = Vector2(80, complete_y)
	groom_complete_label.size = Vector2(560, 54)
	groom_complete_label.visible = cleanliness >= 100
	groom_complete_label.add_theme_color_override("font_outline_color", WHITE)
	groom_complete_label.add_theme_constant_override("outline_size", 5)
	screen_layer.add_child(groom_complete_label)

	var done := _button(_t("GROOM_DONE"), Rect2(120, done_y, 480, 106), PINK, PINK_DARK)
	done.z_index = 100
	done.pressed.connect(_leave_grooming)
	screen_layer.add_child(done)


func _on_groom_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			grooming = true
			groom_drag_accumulator = Vector2.ZERO
			groom_stretch_target = Vector2.ONE
			_groom_at(event.position, Vector2.ZERO)
		else:
			_finish_groom_stretch()
	elif event is InputEventScreenDrag and grooming:
		_groom_at(event.position, event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			grooming = true
			groom_drag_accumulator = Vector2.ZERO
			groom_stretch_target = Vector2.ONE
			_groom_at(event.position, Vector2.ZERO)
		else:
			_finish_groom_stretch()
	elif event is InputEventMouseMotion and grooming:
		_groom_at(event.position, event.relative)


func _groom_at(local_position: Vector2, drag_delta: Vector2) -> void:
	if not is_instance_valid(groom_sprite):
		return
	var half_comb := groom_comb.size / 2.0
	var clamped_pointer := local_position.clamp(half_comb, groom_area.size - half_comb)
	groom_comb.position = clamped_pointer - half_comb
	if drag_delta.length_squared() > 0.1:
		if not _is_over_dragon(local_position):
			groom_drag_accumulator *= 0.72
			groom_stretch_target = Vector2.ONE
			groom_rotation_target = 0.0
			return
		var previous_cleanliness := cleanliness
		cleanliness = minf(100.0, cleanliness + drag_delta.length() * GROOM_CLEAN_PER_PIXEL)
		if floori(cleanliness) != floori(previous_cleanliness):
			_update_clean_display()
			_spawn_groom_sparkle(groom_area.position + local_position)
		_update_continuous_stretch(drag_delta)
		if previous_cleanliness < 100.0 and cleanliness >= 100.0:
			_complete_grooming()


func _is_over_dragon(local_position: Vector2) -> bool:
	if dragon_alpha_image == null or not is_instance_valid(groom_area):
		return false
	var texture_size := Vector2(active_dragon_texture.get_width(), active_dragon_texture.get_height())
	var sprite_local_position := groom_area.position + local_position - groom_sprite.position
	var display_scale: float = minf(groom_sprite.size.x / texture_size.x, groom_sprite.size.y / texture_size.y)
	var displayed_size := texture_size * display_scale
	var display_offset := (groom_sprite.size - displayed_size) * 0.5
	var image_position := (sprite_local_position - display_offset) / display_scale
	if image_position.x < 0.0 or image_position.y < 0.0:
		return false
	if image_position.x >= texture_size.x or image_position.y >= texture_size.y:
		return false
	return dragon_alpha_image.get_pixelv(Vector2i(image_position)).a > 0.15


func _update_continuous_stretch(drag_delta: Vector2) -> void:
	# Accumulate recent motion so deformation flows continuously with the stroke
	# instead of restarting an elastic animation for every input event.
	groom_drag_accumulator = (groom_drag_accumulator * 0.82 + drag_delta * 4.0).limit_length(95.0)
	var horizontal_strength := absf(groom_drag_accumulator.x) / 95.0
	var vertical_strength := absf(groom_drag_accumulator.y) / 95.0
	groom_stretch_target = Vector2(
		1.0 + horizontal_strength * 0.14 - vertical_strength * 0.04,
		1.0 + vertical_strength * 0.16 - horizontal_strength * 0.04
	)
	groom_rotation_target = clampf(groom_drag_accumulator.x / 2400.0, -0.035, 0.035)


func _finish_groom_stretch() -> void:
	grooming = false
	groom_stretch_target = Vector2.ONE
	groom_rotation_target = 0.0
	groom_drag_accumulator = Vector2.ZERO


func _update_clean_display() -> void:
	if is_instance_valid(clean_bar):
		clean_bar.value = cleanliness
	if is_instance_valid(clean_label):
		clean_label.text = "%d%%" % floori(cleanliness)
	if is_instance_valid(groom_complete_label):
		groom_complete_label.visible = cleanliness >= 100


func _complete_grooming() -> void:
	if groom_completion_started or current_screen != "groom":
		return
	groom_completion_started = true
	_finish_groom_stretch()
	GameState.save_game()
	_update_clean_display()
	var celebration_origin := Vector2(
		canvas_size.x * 0.5,
		groom_area.position.y + groom_area.size.y * 0.34
	)
	_burst_confetti(screen_layer, celebration_origin, 46, 3900)
	groom_completion_tween = create_tween()
	groom_completion_tween.tween_interval(1.55)
	groom_completion_tween.tween_callback(_finish_grooming)


func _finish_grooming() -> void:
	if current_screen == "groom":
		call_deferred("_show_habitat")


func _leave_grooming() -> void:
	GameState.save_game()
	_show_habitat()


func _spawn_groom_sparkle(at_position: Vector2) -> void:
	var sparkle := _label("✦", 27, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	sparkle.position = at_position - Vector2(20, 20)
	sparkle.size = Vector2(40, 40)
	sparkle.z_index = 60
	sparkle.add_theme_color_override("font_outline_color", PINK_DARK)
	sparkle.add_theme_constant_override("outline_size", 4)
	screen_layer.add_child(sparkle)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sparkle, "position:y", sparkle.position.y - 34.0, 0.45)
	tween.tween_property(sparkle, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(sparkle.queue_free)


func _show_competition() -> void:
	_show_flight_hub()


func _show_flight_hub() -> void:
	_clear_screen()
	current_screen = "flight_hub"
	var top_y := _safe_top_y(32.0)
	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var wash := ColorRect.new()
	wash.position = Vector2.ZERO
	wash.size = canvas_size
	wash.color = Color(0.98, 0.69, 0.82, 0.14)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(wash)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, top_y)
	top_panel.size = Vector2(672, 104)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.97), INK, 18, 6))
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_show_main_menu)
	top_panel.add_child(back)
	var title := _label(_t("FLIGHT_HUB_TITLE"), 40, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(96, 14)
	title.size = Vector2(480, 70)
	top_panel.add_child(title)

	var dragon := _texture_rect(
		FLIGHT_DRAGON_TEXTURE,
		Rect2(90, top_y + 150, 540, 330),
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	dragon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen_layer.add_child(dragon)

	var xp := GameState.get_flight_xp(selected_dragon_id)
	var level := GameState.get_flight_level(selected_dragon_id)
	var progress := xp % GameState.FLIGHT_XP_PER_LEVEL
	var stats := Panel.new()
	stats.position = Vector2(72, top_y + 490)
	stats.size = Vector2(576, 150)
	stats.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 18, 6))
	screen_layer.add_child(stats)
	var level_label := _label(
		_t("FLIGHT_LEVEL", {"level": level}),
		34,
		PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	level_label.position = Vector2(20, 12)
	level_label.size = Vector2(536, 48)
	stats.add_child(level_label)
	var xp_label := _label(
		_t("FLIGHT_XP_PROGRESS", {"current": progress, "required": GameState.FLIGHT_XP_PER_LEVEL}),
		23,
		INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
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
	xp_bar.add_theme_stylebox_override("background", _panel_style(Color("#e3d4b8"), INK, 7, 0))
	xp_bar.add_theme_stylebox_override("fill", _panel_style(PINK, INK, 7, 0))
	stats.add_child(xp_bar)

	var training := _button(_t("FLIGHT_TRAINING"), Rect2(72, top_y + 690, 576, 118), PINK, PINK_DARK)
	training.pressed.connect(_show_flight_training)
	screen_layer.add_child(training)
	_add_button_caption(training, _t("FLIGHT_TRAINING_CAPTION"))

	var contest := _button(_t("FLIGHT_CONTEST"), Rect2(72, top_y + 845, 576, 118), GOLD, Color("#d38a38"))
	contest.disabled = not GameState.can_enter_flight_contest(selected_dragon_id)
	contest.pressed.connect(_show_flight_contest)
	screen_layer.add_child(contest)
	_add_button_caption(
		contest,
		_t("FLIGHT_CONTEST_CAPTION") if not contest.disabled else _t(
			"FLIGHT_CONTEST_LOCKED",
			{"level": GameState.FLIGHT_CONTEST_LEVEL}
		)
	)


func _show_flight_training() -> void:
	_clear_screen()
	current_screen = "flight_training"
	flight_run_start_level = GameState.get_flight_level(selected_dragon_id)
	var top_y := _safe_top_y(32.0)
	var game_top := top_y + 126.0
	var game := FLIGHT_GAME.new()
	game.position = Vector2.ZERO + Vector2(0, game_top)
	game.size = Vector2(canvas_size.x, canvas_size.y - game_top)
	game.score_changed.connect(_on_flight_score_changed)
	game.run_finished.connect(_on_flight_run_finished)
	screen_layer.add_child(game)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, top_y)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.97), INK, 18, 6))
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_show_flight_hub)
	top_panel.add_child(back)
	var title := _label(_t("FLIGHT_TRAINING"), 38, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(94, 8)
	title.size = Vector2(484, 48)
	top_panel.add_child(title)
	flight_score_label = _label(
		_t("FLIGHT_LIVE_SCORE", {"xp": 0, "level": flight_run_start_level}),
		22,
		PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	flight_score_label.position = Vector2(94, 54)
	flight_score_label.size = Vector2(484, 34)
	top_panel.add_child(flight_score_label)

	var tap_hint := Panel.new()
	tap_hint.position = Vector2(142, game_top + 44)
	tap_hint.size = Vector2(436, 70)
	tap_hint.z_index = 90
	tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tap_hint.add_theme_stylebox_override("panel", _panel_style(Color(0.19, 0.13, 0.25, 0.88), INK, 12, 3))
	screen_layer.add_child(tap_hint)
	var hint_label := _label(_t("FLIGHT_TAP_HINT"), 24, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	tap_hint.add_child(hint_label)
	var hide_hint := create_tween()
	hide_hint.tween_interval(2.2)
	hide_hint.tween_property(tap_hint, "modulate:a", 0.0, 0.5)


func _on_flight_score_changed(score: int) -> void:
	GameState.add_flight_xp(selected_dragon_id, 1)
	if is_instance_valid(flight_score_label):
		flight_score_label.text = _t(
			"FLIGHT_LIVE_SCORE",
			{"xp": score, "level": GameState.get_flight_level(selected_dragon_id)}
		)


func _on_flight_run_finished(score: int, _completed: bool) -> void:
	var previous_level := flight_run_start_level
	var new_level := GameState.get_flight_level(selected_dragon_id)
	var overlay := Control.new()
	overlay.position = Vector2.ZERO
	overlay.size = canvas_size
	overlay.z_index = 4000
	screen_layer.add_child(overlay)
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = canvas_size
	dim.color = Color(0.10, 0.07, 0.14, 0.68)
	overlay.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(60, canvas_size.y * 0.5 - 285)
	panel.size = Vector2(600, 570)
	panel.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 24, 10))
	overlay.add_child(panel)
	var result_title := _label(
		_t("FLIGHT_ROUND_OVER"),
		40,
		PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	result_title.position = Vector2(30, 40)
	result_title.size = Vector2(540, 64)
	panel.add_child(result_title)
	var xp_result := _label(
		_t("FLIGHT_XP_EARNED", {"xp": score}),
		30,
		GOLD,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	xp_result.position = Vector2(30, 120)
	xp_result.size = Vector2(540, 54)
	panel.add_child(xp_result)
	var level_result := _label(
		_t("FLIGHT_LEVEL_UP", {"level": new_level}) if new_level > previous_level else _t(
			"FLIGHT_LEVEL",
			{"level": new_level}
		),
		27,
		INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	level_result.position = Vector2(30, 185)
	level_result.size = Vector2(540, 52)
	panel.add_child(level_result)
	var progress_note := _label(
		_t("FLIGHT_CONTEST_READY") if GameState.can_enter_flight_contest(selected_dragon_id) else _t(
			"FLIGHT_LEVELS_TO_GO",
			{"count": GameState.FLIGHT_CONTEST_LEVEL - new_level}
		),
		24,
		INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	progress_note.position = Vector2(55, 245)
	progress_note.size = Vector2(490, 76)
	progress_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(progress_note)
	var retry := _button(_t("FLIGHT_RETRY"), Rect2(80, 340, 440, 82), PINK, PINK_DARK)
	retry.add_theme_font_size_override("font_size", 31)
	retry.pressed.connect(_show_flight_training)
	panel.add_child(retry)
	var hub := _button(_t("FLIGHT_BACK_TO_HUB"), Rect2(80, 444, 440, 82), Color("#8ed5aa"), Color("#4d9a70"))
	hub.add_theme_font_size_override("font_size", 29)
	hub.pressed.connect(_show_flight_hub)
	panel.add_child(hub)


func _show_flight_contest() -> void:
	if not GameState.can_enter_flight_contest(selected_dragon_id):
		_show_flight_hub()
		return
	_clear_screen()
	current_screen = "flight_contest"
	var top_y := _safe_top_y(32.0)
	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var top_panel := Panel.new()
	top_panel.position = Vector2(24, top_y)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.97), INK, 18, 6))
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.disabled = true
	top_panel.add_child(back)
	var title := _label(_t("FLIGHT_CONTEST"), 38, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(94, 8)
	title.size = Vector2(484, 48)
	top_panel.add_child(title)
	flight_distance_label = _label(
		_t("FLIGHT_DISTANCE", {"meters": 0}),
		22,
		PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	flight_distance_label.position = Vector2(94, 54)
	flight_distance_label.size = Vector2(484, 34)
	top_panel.add_child(flight_distance_label)

	var ground := ColorRect.new()
	ground.position = Vector2(0, canvas_size.y - 155)
	ground.size = Vector2(canvas_size.x, 155)
	ground.color = Color("#8ed5aa")
	screen_layer.add_child(ground)
	var ground_edge := ColorRect.new()
	ground_edge.position = Vector2(0, canvas_size.y - 162)
	ground_edge.size = Vector2(canvas_size.x, 8)
	ground_edge.color = INK
	screen_layer.add_child(ground_edge)

	var dragon := _texture_rect(
		FLIGHT_DRAGON_TEXTURE,
		Rect2(38, top_y + 245, 240, 152),
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	dragon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dragon.flip_h = true
	dragon.pivot_offset = dragon.size / 2.0
	dragon.z_index = 40
	screen_layer.add_child(dragon)
	var target_distance := GameState.flight_contest_distance(selected_dragon_id)
	var duration := 3.2 + minf(3.0, GameState.get_flight_level(selected_dragon_id) * 0.35)
	var landing_y := canvas_size.y - 300.0
	flight_contest_tween = create_tween()
	flight_contest_tween.tween_interval(0.65)
	flight_contest_tween.set_parallel(true)
	flight_contest_tween.tween_property(dragon, "position:x", 435.0, duration).set_trans(Tween.TRANS_SINE)
	flight_contest_tween.tween_property(dragon, "position:y", landing_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight_contest_tween.tween_property(dragon, "rotation", 0.20, duration).set_trans(Tween.TRANS_SINE)
	flight_contest_tween.tween_method(_update_flight_distance, 0.0, float(target_distance), duration)
	flight_contest_tween.set_parallel(false)
	flight_contest_tween.tween_callback(_complete_flight_contest.bind(target_distance))


func _update_flight_distance(value: float) -> void:
	if is_instance_valid(flight_distance_label):
		flight_distance_label.text = _t("FLIGHT_DISTANCE", {"meters": floori(value)})


func _complete_flight_contest(distance: int) -> void:
	var reward := GameState.complete_flight_contest(selected_dragon_id)
	var overlay := Control.new()
	overlay.position = Vector2.ZERO
	overlay.size = canvas_size
	overlay.z_index = 4000
	screen_layer.add_child(overlay)
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = canvas_size
	dim.color = Color(0.10, 0.07, 0.14, 0.64)
	overlay.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(60, canvas_size.y * 0.5 - 250)
	panel.size = Vector2(600, 500)
	panel.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 24, 10))
	overlay.add_child(panel)
	var title := _label(_t("FLIGHT_CONTEST_RESULT"), 38, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(25, 40)
	title.size = Vector2(550, 60)
	panel.add_child(title)
	var distance_label := _label(
		_t("FLIGHT_DISTANCE_RESULT", {"meters": distance}),
		34,
		INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	distance_label.position = Vector2(25, 118)
	distance_label.size = Vector2(550, 58)
	panel.add_child(distance_label)
	var reward_label := _label(
		_t("FLIGHT_GOLD_REWARD", {"gold": reward}),
		31,
		GOLD,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	reward_label.position = Vector2(25, 198)
	reward_label.size = Vector2(550, 58)
	panel.add_child(reward_label)
	var shop := _button(_t("FLIGHT_GO_TO_SHOP"), Rect2(80, 304, 440, 96), PINK, PINK_DARK)
	shop.add_theme_font_size_override("font_size", 31)
	shop.pressed.connect(_show_shop)
	panel.add_child(shop)
	_burst_confetti(overlay, panel.position + Vector2(300, 180), 44, 20)


func _show_beauty_competition() -> void:
	_clear_screen()
	current_screen = "competition"
	var judge_y := canvas_size.y - 142.0
	var item_row_y := judge_y - 170.0
	var stage_height := minf(760.0, item_row_y - 315.0)
	var stage_scale := minf(1.0, stage_height / 720.0)

	var sky := PIXEL_ART.PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var wash := ColorRect.new()
	wash.position = Vector2.ZERO
	wash.size = canvas_size
	wash.color = Color(0.82, 0.72, 1.0, 0.22)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(wash)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, 32)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.97), INK, 18, 6))
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_show_main_menu)
	top_panel.add_child(back)
	var title := _label(_t("CONTEST_TITLE"), 36, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(98, 14)
	title.size = Vector2(474, 70)
	top_panel.add_child(title)

	var instruction := Panel.new()
	instruction.position = Vector2(82, 160)
	instruction.size = Vector2(556, 66)
	instruction.add_theme_stylebox_override("panel", _panel_style(Color(0.19, 0.13, 0.25, 0.92), INK, 12, 3))
	screen_layer.add_child(instruction)
	var instruction_text := _label(_t("CONTEST_INSTRUCTION"), 24, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	instruction_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	instruction.add_child(instruction_text)

	var stage_panel := Panel.new()
	stage_panel.position = Vector2(40, 245)
	stage_panel.size = Vector2(640, stage_height)
	stage_panel.clip_contents = true
	stage_panel.add_theme_stylebox_override("panel", _panel_style(Color("#bdeaf7"), INK, 22, 7))
	screen_layer.add_child(stage_panel)

	var stage_content := Control.new()
	stage_content.position = Vector2(0, (stage_height - 720.0 * stage_scale) * 0.5)
	stage_content.size = Vector2(640, 720)
	stage_content.scale = Vector2.ONE * stage_scale
	stage_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_panel.add_child(stage_content)

	var dragon := _texture_rect(DRAGON_TEXTURE, Rect2(50, 70, 540, 560), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	dragon.z_index = 10
	stage_content.add_child(dragon)

	var sword := PIXEL_ART.AccessoryArt.new("sword")
	sword.position = accessory_positions["sword"]
	sword.size = Vector2(92, 220)
	sword.rotation = 0.55
	stage_content.add_child(sword)
	_register_accessory("sword", sword)

	var hat := PIXEL_ART.AccessoryArt.new("hat")
	hat.position = accessory_positions["hat"]
	hat.size = Vector2(120, 100)
	stage_content.add_child(hat)
	_register_accessory("hat", hat)

	var shield := PIXEL_ART.AccessoryArt.new("shield")
	shield.position = accessory_positions["shield"]
	shield.size = Vector2(130, 150)
	stage_content.add_child(shield)
	_register_accessory("shield", shield)

	var bowtie := PIXEL_ART.AccessoryArt.new("bowtie")
	bowtie.position = accessory_positions["bowtie"]
	bowtie.size = Vector2(92, 72)
	stage_content.add_child(bowtie)
	_register_accessory("bowtie", bowtie)

	var tie := PIXEL_ART.AccessoryArt.new("tie")
	tie.position = accessory_positions["tie"]
	tie.size = Vector2(64, 132)
	stage_content.add_child(tie)
	_register_accessory("tie", tie)

	competition_drag_area = Control.new()
	competition_drag_area.position = Vector2.ZERO
	competition_drag_area.size = stage_content.size
	competition_drag_area.mouse_filter = Control.MOUSE_FILTER_STOP
	competition_drag_area.mouse_default_cursor_shape = Control.CURSOR_DRAG
	competition_drag_area.z_index = 3000
	competition_drag_area.gui_input.connect(_on_competition_drag_input)
	stage_content.add_child(competition_drag_area)

	var items_title := _label(_t("CONTEST_ITEMS"), 23, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	items_title.position = Vector2(0, item_row_y - 48)
	items_title.size = Vector2(720, 38)
	screen_layer.add_child(items_title)

	var item_specs := [
		["hat", "ITEM_HAT"],
		["sword", "ITEM_SWORD"],
		["shield", "ITEM_SHIELD"],
		["bowtie", "ITEM_BOWTIE"],
		["tie", "ITEM_TIE"],
	]
	for index in item_specs.size():
		var kind: String = item_specs[index][0]
		var label_key: String = item_specs[index][1]
		var item_button := _competition_item_button(kind, _t(label_key), Vector2(32 + index * 132, item_row_y))
		screen_layer.add_child(item_button)

	var enter := _button(_t("ENTER_CONTEST"), Rect2(120, judge_y, 480, 106), PINK, PINK_DARK)
	enter.pressed.connect(_judge_competition)
	screen_layer.add_child(enter)


func _register_accessory(kind: String, art: Control) -> void:
	accessory_nodes[kind] = art
	art.visible = bool(selected_accessories.get(kind, false))
	art.z_index = accessory_z_counter
	accessory_z_counter += 1


func _competition_item_button(kind: String, label_text: String, position_value: Vector2) -> Button:
	var button := Button.new()
	button.position = position_value
	button.size = Vector2(120, 130)
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.button_pressed = bool(selected_accessories.get(kind, false))
	button.add_theme_stylebox_override("normal", _panel_style(WHITE, INK, 14, 5))
	button.add_theme_stylebox_override("hover", _panel_style(CREAM, PINK_DARK, 14, 5))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#ffd1e4"), PINK_DARK, 14, 3))
	var icon := PIXEL_ART.AccessoryArt.new(kind)
	icon.position = Vector2(31, 8)
	icon.size = Vector2(58, 72)
	button.add_child(icon)
	var item_label := _label(label_text, 18, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	item_label.position = Vector2(4, 88)
	item_label.size = Vector2(112, 32)
	button.add_child(item_label)
	button.toggled.connect(_on_accessory_toggled.bind(kind))
	accessory_buttons[kind] = button
	return button


func _on_accessory_toggled(enabled: bool, kind: String) -> void:
	selected_accessories[kind] = enabled
	var art: Variant = accessory_nodes.get(kind)
	if is_instance_valid(art):
		art.visible = enabled
		if enabled:
			_bring_accessory_to_front(kind)


func _on_competition_drag_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_accessory_drag(event.position)
		else:
			_end_accessory_drag()
	elif event is InputEventScreenDrag and not dragged_accessory_kind.is_empty():
		_drag_accessory_to(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_accessory_drag(event.position)
		else:
			_end_accessory_drag()
	elif event is InputEventMouseMotion and not dragged_accessory_kind.is_empty():
		_drag_accessory_to(event.position)


func _begin_accessory_drag(pointer_position: Vector2) -> void:
	var top_kind := ""
	var top_z := -1
	for kind_variant in accessory_nodes:
		var kind: String = kind_variant
		var art: Control = accessory_nodes[kind]
		if not art.visible:
			continue
		var point_in_art := art.get_transform().affine_inverse() * pointer_position
		if Rect2(Vector2.ZERO, art.size).has_point(point_in_art) and art.z_index > top_z:
			top_kind = kind
			top_z = art.z_index
	if top_kind.is_empty():
		return
	dragged_accessory_kind = top_kind
	var dragged_art: Control = accessory_nodes[top_kind]
	accessory_drag_offset = pointer_position - dragged_art.position
	_bring_accessory_to_front(top_kind)


func _drag_accessory_to(pointer_position: Vector2) -> void:
	var art := accessory_nodes.get(dragged_accessory_kind) as Control
	if art == null or not is_instance_valid(competition_drag_area):
		_end_accessory_drag()
		return
	var max_position: Vector2 = competition_drag_area.size - art.size
	art.position = (pointer_position - accessory_drag_offset).clamp(Vector2.ZERO, max_position)
	accessory_positions[dragged_accessory_kind] = art.position


func _bring_accessory_to_front(kind: String) -> void:
	var art := accessory_nodes.get(kind) as Control
	if art == null:
		return
	accessory_z_counter += 1
	art.z_index = accessory_z_counter


func _end_accessory_drag() -> void:
	dragged_accessory_kind = ""
	accessory_drag_offset = Vector2.ZERO


func _judge_competition() -> void:
	if is_instance_valid(competition_result_overlay):
		return
	competition_result_overlay = Control.new()
	competition_result_overlay.position = Vector2.ZERO
	competition_result_overlay.size = canvas_size
	competition_result_overlay.z_index = 4000
	screen_layer.add_child(competition_result_overlay)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = canvas_size
	dim.color = Color(0.10, 0.07, 0.14, 0.68)
	competition_result_overlay.add_child(dim)

	var result_panel := Panel.new()
	result_panel.position = Vector2(60, canvas_size.y * 0.5 - 300)
	result_panel.size = Vector2(600, 600)
	result_panel.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 24, 10))
	competition_result_overlay.add_child(result_panel)

	var judge_title := _label(_t("JUDGE_TITLE"), 28, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	judge_title.position = Vector2(30, 34)
	judge_title.size = Vector2(540, 50)
	result_panel.add_child(judge_title)
	var perfect := _label(_t("PERFECT_SCORE"), 43, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	perfect.position = Vector2(20, 100)
	perfect.size = Vector2(560, 64)
	result_panel.add_child(perfect)
	var score_stars: Array[Control] = []
	for star_index in 5:
		var star := PIXEL_ART.PixelStar.new()
		star.position = Vector2(96 + star_index * 84, 178)
		star.size = Vector2(72, 72)
		star.scale = Vector2.ONE * 0.08
		star.modulate.a = 0.0
		result_panel.add_child(star)
		score_stars.append(star)
	var score := PIXEL_ART.PixelScore.new()
	score.position = Vector2(190, 258)
	score.size = Vector2(220, 74)
	score.scale = Vector2.ONE * 0.82
	score.modulate.a = 0.0
	result_panel.add_child(score)
	var comment := _label(_t("JUDGE_COMMENT"), 24, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	comment.position = Vector2(58, 330)
	comment.size = Vector2(484, 90)
	comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_panel.add_child(comment)
	var continue_button := _button(_t("CONTINUE"), Rect2(80, 460, 440, 96), PINK, PINK_DARK)
	continue_button.pressed.connect(_finish_competition)
	result_panel.add_child(continue_button)
	_animate_competition_score(score_stars, score, result_panel.position + Vector2(300, 220))


func _animate_competition_score(stars: Array[Control], score: Control, confetti_origin: Vector2) -> void:
	competition_result_tween = create_tween()
	competition_result_tween.tween_interval(0.18)
	for star in stars:
		competition_result_tween.tween_callback(_reveal_score_star.bind(star))
		competition_result_tween.tween_property(star, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		competition_result_tween.tween_interval(0.08)
	competition_result_tween.tween_callback(_burst_score_confetti.bind(confetti_origin))
	competition_result_tween.tween_callback(_reveal_score_display.bind(score))
	competition_result_tween.tween_property(score, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	competition_result_tween.tween_interval(1.55)
	competition_result_tween.tween_callback(_finish_competition)


func _reveal_score_star(star: Control) -> void:
	if is_instance_valid(star):
		star.modulate.a = 1.0


func _reveal_score_display(score: Control) -> void:
	if is_instance_valid(score):
		score.modulate.a = 1.0


func _burst_score_confetti(origin: Vector2) -> void:
	if not is_instance_valid(competition_result_overlay):
		return
	_burst_confetti(competition_result_overlay, origin, 34, 30)


func _burst_confetti(parent: Control, origin: Vector2, piece_count: int, layer: int) -> void:
	if not is_instance_valid(parent):
		return
	var confetti_colors := [PINK, GOLD, MINT, SKY, Color("#9b7ede"), CREAM]
	for piece_index in piece_count:
		var piece := PIXEL_ART.ConfettiPiece.new()
		piece.position = origin + Vector2(random.randf_range(-18.0, 18.0), random.randf_range(-8.0, 8.0))
		piece.size = Vector2(random.randi_range(10, 17), random.randi_range(16, 27))
		piece.velocity = Vector2(random.randf_range(-330.0, 330.0), random.randf_range(-570.0, -280.0))
		piece.spin = random.randf_range(-9.0, 9.0)
		piece.piece_color = confetti_colors[piece_index % confetti_colors.size()]
		piece.z_index = layer
		parent.add_child(piece)


func _finish_competition() -> void:
	if current_screen == "competition":
		call_deferred("_show_habitat")


func _feed_dragon() -> void:
	if walking or not is_instance_valid(dragon_actor):
		return
	walking = true
	feed_button.disabled = true
	var target := Vector2(
		random.randf_range(155.0, 565.0),
		random.randf_range(500.0 + _island_vertical_offset(), 790.0 + _island_vertical_offset())
	)
	var berry := PIXEL_ART.BerryPickup.new()
	berry.size = Vector2(64, 64)
	berry.position = target - Vector2(32, 210)
	berry.scale = Vector2(0.25, 0.25)
	berry.z_index = int(target.y) - 1
	screen_layer.add_child(berry)

	var drop := create_tween().set_parallel(true)
	drop.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.tween_property(berry, "position", target - Vector2(32, 32), 0.48)
	drop.tween_property(berry, "scale", Vector2.ONE, 0.32)
	await drop.finished
	if not is_instance_valid(dragon_actor) or current_screen != "habitat":
		return

	var actor_target := target - DRAGON_FOOT_ANCHOR
	var distance := dragon_actor.position.distance_to(actor_target)
	var walk_duration := clampf(distance / 185.0, 0.7, 2.4)
	dragon_actor.z_index = int(target.y)
	var walk := create_tween()
	walk.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	walk.tween_property(dragon_actor, "position", actor_target, walk_duration)
	await walk.finished
	if not is_instance_valid(berry) or current_screen != "habitat":
		return

	var eat := create_tween().set_parallel(true)
	eat.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	eat.tween_property(berry, "scale", Vector2.ZERO, 0.24)
	eat.tween_property(berry, "rotation", 0.4, 0.24)
	await eat.finished
	berry.queue_free()
	hunger = mini(100, hunger + 18)
	care_points += 5
	hunger_bar.value = hunger
	hunger_label.text = "%d%%" % hunger
	care_label.text = _t("CARE_POINTS", {"value": care_points})
	GameState.save_game()
	_show_care_pop(target)
	walking = false
	feed_button.disabled = false


func _show_care_pop(at_position: Vector2) -> void:
	var pop := _label(_t("CARE_POP"), 27, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	pop.position = at_position + Vector2(-90, -120)
	pop.size = Vector2(180, 44)
	pop.z_index = 1200
	pop.add_theme_color_override("font_outline_color", WHITE)
	pop.add_theme_constant_override("outline_size", 6)
	screen_layer.add_child(pop)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(pop, "position:y", pop.position.y - 75.0, 0.8)
	tween.tween_property(pop, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(pop.queue_free)


func _texture_rect(texture: Texture2D, rect: Rect2, stretch: TextureRect.StretchMode) -> TextureRect:
	var result := TextureRect.new()
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = stretch
	result.texture = texture
	result.position = rect.position
	result.size = rect.size
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


func _label(text_value: String, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT, font := FONT_REGULAR) -> Label:
	var result := Label.new()
	result.text = text_value
	result.horizontal_alignment = alignment
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_override("font", font)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


func _button(text_value: String, rect: Rect2, color: Color, shadow_color: Color) -> Button:
	var result := Button.new()
	result.text = text_value
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", FONT_BOLD)
	result.add_theme_font_size_override("font_size", 40)
	result.add_theme_color_override("font_color", WHITE)
	result.add_theme_color_override("font_hover_color", WHITE)
	result.add_theme_color_override("font_pressed_color", WHITE)
	result.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.75))
	result.add_theme_constant_override("outline_size", 4)
	result.add_theme_color_override("font_outline_color", INK)
	result.add_theme_stylebox_override("normal", _panel_style(color, INK, 14, 8, shadow_color))
	result.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.08), INK, 14, 8, shadow_color))
	result.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.06), INK, 14, 3, shadow_color))
	result.add_theme_stylebox_override("disabled", _panel_style(color.darkened(0.16), INK_SOFT, 14, 5, shadow_color.darkened(0.18)))
	return result


func _small_button(text_value: String, rect: Rect2, color: Color) -> Button:
	var result := Button.new()
	result.text = text_value
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_override("font", FONT_BOLD)
	result.add_theme_font_size_override("font_size", 46)
	result.add_theme_color_override("font_color", INK)
	result.add_theme_stylebox_override("normal", _panel_style(color, INK, 12, 5))
	result.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.08), PINK_DARK, 12, 5))
	result.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.05), INK, 12, 2))
	return result


func _panel_style(color: Color, border: Color, radius: int, shadow_size: int = 0, shadow_color := Color(0.16, 0.10, 0.20, 0.35)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, shadow_size)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _badge(text_value: String, rect: Rect2, color: Color, text_color: Color) -> Panel:
	var badge := Panel.new()
	badge.position = rect.position
	badge.size = rect.size
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _panel_style(color, INK, 9, 2))
	var text_label := _label(text_value, 19, text_color, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	badge.add_child(text_label)
	return badge


func _add_button_caption(button: Button, caption: String) -> void:
	button.text = button.text + "\n" + caption
	button.add_theme_font_size_override("font_size", 31)


func _add_resource_pill(position_value: Vector2, amount: int, icon_kind: String, accent: Color) -> void:
	var pill := Panel.new()
	pill.position = position_value
	pill.size = Vector2(172, 62)
	pill.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.92), INK, 14, 4))
	screen_layer.add_child(pill)
	var icon := PIXEL_ART.ResourceIcon.new()
	icon.icon_kind = icon_kind
	icon.position = Vector2(20, 11)
	icon.size = Vector2(38, 40)
	pill.add_child(icon)
	var pill_text := _label(str(amount), 27, accent, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	pill_text.position = Vector2(59, 0)
	pill_text.size = Vector2(94, 62)
	pill.add_child(pill_text)


func _t(key: String, values: Dictionary = {}) -> String:
	return Localization.text(key, values)


func _on_locale_changed(_locale: String) -> void:
	_rebuild_current_screen()


func _rebuild_current_screen() -> void:
	match current_screen:
		"den":
			_show_den()
		"dragons":
			_show_dragons()
		"eggs":
			_show_eggs()
		"egg_detail":
			_show_egg_detail(current_egg_id)
		"shop":
			_show_shop()
		"habitat":
			_show_habitat()
		"groom":
			_show_grooming()
		"flight_hub":
			_show_competition()
		"flight_training":
			_show_flight_training()
		"flight_contest":
			_show_flight_contest()
		_:
			_show_main_menu()


func debug_groom_stroke() -> void:
	if current_screen != "groom":
		_show_grooming()
	grooming = true
	groom_drag_accumulator = Vector2.ZERO
	for index in 480:
		var column := index % 8
		var row := (index / 8) % 6
		var point := groom_sprite.position - groom_area.position + Vector2(
			groom_sprite.size.x * (0.20 + column * 0.085),
			groom_sprite.size.y * (0.28 + row * 0.085)
		)
		_groom_at(point, Vector2(58, 12))
		if cleanliness >= 100.0:
			break


func debug_groom_off_sprite() -> void:
	if current_screen != "groom":
		_show_grooming()
	grooming = true
	var clean_before := cleanliness
	_groom_at(Vector2(groom_area.size.x - 12.0, 32.0), Vector2(54, 0))
	assert(cleanliness == clean_before, "Off-sprite grooming must not increase Clean.")


func debug_competition_drag() -> void:
	selected_accessories["hat"] = true
	selected_accessories["shield"] = true
	_show_beauty_competition()
	var hat := accessory_nodes["hat"] as Control
	var shield := accessory_nodes["shield"] as Control
	_begin_accessory_drag(hat.position + hat.size / 2.0)
	_drag_accessory_to(Vector2(390, 255))
	_end_accessory_drag()
	_begin_accessory_drag(shield.position + shield.size / 2.0)
	_drag_accessory_to(Vector2(380, 350))
	_end_accessory_drag()
	assert(shield.z_index > hat.z_index, "The most recently dragged accessory must be on top.")


func debug_set_locale(locale_code: String) -> void:
	Localization.set_locale(locale_code)


func debug_add_ice_dragon() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("species", "sunwing")) == "ice":
			return String(dragon.get("id"))
	var dragon_id := "debug-ice-dragon"
	GameState.dragons.append({
		"id": dragon_id,
		"name_key": "ICE_DRAGON_NAME",
		"species": "ice",
		"starter": false,
		"flight_xp": 0,
	})
	return dragon_id


func debug_show_screen(screen_name: String) -> void:
	match screen_name:
		"den":
			_show_den()
		"shop":
			GameState.gold = 1
			_show_shop()
		"ice_egg":
			GameState.gold = 1
			_show_shop()
			_purchase_egg()
		"dragons_ice":
			debug_add_ice_dragon()
			_show_dragons()
		"ice_island":
			selected_dragon_id = debug_add_ice_dragon()
			_show_habitat()
		"habitat":
			_show_habitat()
		"groom":
			_show_grooming()
		"groomed":
			_show_grooming()
			debug_groom_stroke()
		"groom_off":
			_show_grooming()
			debug_groom_off_sprite()
		"competition":
			_show_competition()
		"flight_training":
			_show_flight_training()
			for child in screen_layer.get_children():
				if child.get_script() == FLIGHT_GAME:
					child.call("debug_show_obstacle")
					break
		"flight_contest":
			GameState.add_flight_xp(
				selected_dragon_id,
				maxi(0, GameState.FLIGHT_CONTEST_LEVEL * GameState.FLIGHT_XP_PER_LEVEL - GameState.get_flight_xp(selected_dragon_id))
			)
			_show_flight_contest()
		"result":
			GameState.add_flight_xp(
				selected_dragon_id,
				maxi(0, GameState.FLIGHT_CONTEST_LEVEL * GameState.FLIGHT_XP_PER_LEVEL - GameState.get_flight_xp(selected_dragon_id))
			)
			_show_flight_contest()
			_complete_flight_contest(GameState.flight_contest_distance(selected_dragon_id))
		_:
			_show_main_menu()
