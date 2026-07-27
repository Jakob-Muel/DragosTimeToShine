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
const FONT_REGULAR := preload("res://assets/fonts/PixelifySans-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/PixelifySans-Bold.ttf")

const DESIGN_WIDTH := 720.0
const BASE_DESIGN_HEIGHT := 1565.373
const DRAGON_FOOT_ANCHOR := Vector2(105.0, 218.0)

var screen_layer: Control
var canvas_size := Vector2(DESIGN_WIDTH, BASE_DESIGN_HEIGHT)
var layout_ready := false
var layout_rebuild_queued := false
var current_screen := "main"
var dragon_actor: Control
var dragon_sprite: TextureRect
var dragon_shadow: BlobShadow
var feed_button: Button
var hunger_bar: ProgressBar
var hunger_label: Label
var clean_bar: ProgressBar
var clean_label: Label
var care_label: Label
var groom_button: Button
var groom_area: Control
var groom_sprite: TextureRect
var groom_comb: PixelComb
var groom_complete_label: Label
var dragon_alpha_image: Image
var groom_stretch_target := Vector2.ONE
var groom_rotation_target := 0.0
var groom_drag_accumulator := Vector2.ZERO
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
var walking := false
var grooming := false
var bob_time := 0.0
var hunger := 42
var cleanliness := 28
var care_points := 18
var random := RandomNumberGenerator.new()


class PixelSky:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#75d8f2"))
		draw_rect(Rect2(0, size.y * 0.69, size.x, size.y * 0.31), Color("#b7e888"))
		draw_rect(Rect2(0, size.y * 0.69, size.x, 8), Color("#2f2140"))
		_draw_cloud(Vector2(52, 172), 1.0)
		_draw_cloud(Vector2(485, 260), 0.8)
		_draw_cloud(Vector2(115, 510), 0.55)
		for x in range(24, int(size.x), 64):
			var y := int(size.y * 0.73) + (x * 17) % 205
			draw_rect(Rect2(x, y, 8, 18), Color("#65bb65"))
			draw_rect(Rect2(x - 4, y + 7, 4, 5), Color("#65bb65"))
			draw_rect(Rect2(x + 8, y + 4, 4, 5), Color("#65bb65"))

	func _draw_cloud(origin: Vector2, scale_factor: float) -> void:
		var blocks := [
			Rect2(30, 0, 90, 32),
			Rect2(0, 28, 166, 42),
			Rect2(22, 62, 120, 18),
		]
		for block in blocks:
			var scaled := Rect2(origin + block.position * scale_factor, block.size * scale_factor)
			draw_rect(scaled, Color("#fff1c9"))
			draw_rect(Rect2(scaled.position + Vector2(0, scaled.size.y - 6), Vector2(scaled.size.x, 6)), Color("#efcf9c"))


class BlobShadow:
	extends Control

	var squish := 1.0:
		set(value):
			squish = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var points := PackedVector2Array()
		var center := size / 2.0
		for index in 32:
			var angle := TAU * float(index) / 32.0
			points.append(center + Vector2(cos(angle) * size.x * 0.46, sin(angle) * size.y * 0.38 * squish))
		draw_colored_polygon(points, Color(0.16, 0.10, 0.20, 0.28))


class BerryPickup:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		var pixel := 6.0
		var berry := [
			Vector2i(3, 2), Vector2i(4, 2),
			Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
			Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4),
			Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5),
			Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),
			Vector2i(3, 7), Vector2i(4, 7),
		]
		for cell in berry:
			draw_rect(Rect2(Vector2(cell) * pixel + Vector2(7, 5), Vector2(pixel, pixel)), Color("#e63e78"))
		draw_rect(Rect2(25, 11, 6, 12), Color("#49334f"))
		draw_rect(Rect2(31, 5, 12, 6), Color("#49a85b"))
		draw_rect(Rect2(37, 11, 12, 6), Color("#49a85b"))
		draw_rect(Rect2(19, 29, 6, 6), Color("#ff8cba"))
		draw_rect(Rect2(0, 54, 62, 7), Color(0.16, 0.10, 0.20, 0.22))


class PixelComb:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(5, 31, 55, 22), Color("#2f2140"))
		draw_rect(Rect2(9, 35, 51, 14), Color("#fff1c9"))
		draw_rect(Rect2(54, 18, 34, 18), Color("#2f2140"))
		draw_rect(Rect2(58, 22, 26, 10), Color("#f45b9d"))
		for tooth_x in range(58, 86, 7):
			draw_rect(Rect2(tooth_x, 32, 6, 30), Color("#2f2140"))
			draw_rect(Rect2(tooth_x + 1, 32, 4, 25), Color("#f45b9d"))
		draw_rect(Rect2(13, 38, 8, 5), Color("#ffffff"))


class AccessoryArt:
	extends Control

	var item_kind := ""

	func _init(kind: String = "") -> void:
		item_kind = kind

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		match item_kind:
			"hat":
				_rect(8, 63, 84, 18, Color("#2f2140"))
				_rect(14, 67, 72, 10, Color("#f45b9d"))
				_rect(24, 14, 52, 56, Color("#2f2140"))
				_rect(30, 20, 40, 42, Color("#fff1c9"))
				_rect(30, 50, 40, 12, Color("#f45b9d"))
			"sword":
				_poly([Vector2(43, 4), Vector2(59, 4), Vector2(59, 62), Vector2(51, 78), Vector2(43, 62)], Color("#2f2140"))
				_poly([Vector2(47, 10), Vector2(55, 10), Vector2(55, 60), Vector2(51, 69), Vector2(47, 60)], Color("#e9f6ff"))
				_rect(27, 64, 48, 12, Color("#2f2140"))
				_rect(33, 67, 36, 6, Color("#ffc857"))
				_rect(44, 74, 14, 22, Color("#2f2140"))
				_rect(48, 76, 6, 17, Color("#b86f43"))
			"shield":
				_poly([Vector2(12, 12), Vector2(88, 12), Vector2(84, 65), Vector2(50, 94), Vector2(16, 65)], Color("#2f2140"))
				_poly([Vector2(20, 20), Vector2(80, 20), Vector2(76, 61), Vector2(50, 84), Vector2(24, 61)], Color("#ffc857"))
				_rect(44, 29, 12, 44, Color("#fff1c9"))
				_rect(30, 43, 40, 12, Color("#fff1c9"))
			"bowtie":
				_poly([Vector2(7, 24), Vector2(43, 42), Vector2(43, 62), Vector2(7, 80)], Color("#2f2140"))
				_poly([Vector2(93, 24), Vector2(57, 42), Vector2(57, 62), Vector2(93, 80)], Color("#2f2140"))
				_poly([Vector2(14, 34), Vector2(41, 47), Vector2(41, 57), Vector2(14, 70)], Color("#f45b9d"))
				_poly([Vector2(86, 34), Vector2(59, 47), Vector2(59, 57), Vector2(86, 70)], Color("#f45b9d"))
				_rect(40, 39, 20, 28, Color("#2f2140"))
				_rect(45, 44, 10, 18, Color("#fff1c9"))
			"tie":
				_poly([Vector2(36, 8), Vector2(64, 8), Vector2(69, 28), Vector2(50, 41), Vector2(31, 28)], Color("#2f2140"))
				_poly([Vector2(40, 13), Vector2(60, 13), Vector2(63, 25), Vector2(50, 34), Vector2(37, 25)], Color("#f45b9d"))
				_poly([Vector2(42, 35), Vector2(58, 35), Vector2(70, 82), Vector2(50, 96), Vector2(30, 82)], Color("#2f2140"))
				_poly([Vector2(46, 42), Vector2(54, 42), Vector2(63, 78), Vector2(50, 87), Vector2(37, 78)], Color("#f45b9d"))

	func _rect(x: float, y: float, width: float, height: float, color: Color) -> void:
		draw_rect(Rect2(x * size.x / 100.0, y * size.y / 100.0, width * size.x / 100.0, height * size.y / 100.0), color)

	func _poly(source_points: Array[Vector2], color: Color) -> void:
		var points := PackedVector2Array()
		for point in source_points:
			points.append(Vector2(point.x * size.x / 100.0, point.y * size.y / 100.0))
		draw_colored_polygon(points, color)


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
	groom_stretch_target = Vector2.ONE
	groom_rotation_target = 0.0
	groom_drag_accumulator = Vector2.ZERO
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


func _show_main_menu() -> void:
	_clear_screen()
	current_screen = "main"
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

	_add_resource_pill(Vector2(38, 38), "✦  125")
	_add_resource_pill(Vector2(510, 38), "●  430", GOLD)
	var language_button := _small_button(Localization.get_locale().to_upper(), Rect2(300, 38, 120, 62), CREAM)
	language_button.add_theme_font_size_override("font_size", 24)
	language_button.pressed.connect(Localization.cycle_locale)
	screen_layer.add_child(language_button)

	var title_shadow := _label(_t("BRAND_NAME"), 82, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title_shadow.position = Vector2(3, 145)
	title_shadow.size = Vector2(720, 105)
	screen_layer.add_child(title_shadow)
	var title := _label(_t("BRAND_NAME"), 82, PINK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(0, 138)
	title.size = Vector2(720, 105)
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 8)
	screen_layer.add_child(title)

	var ribbon := Panel.new()
	ribbon.position = Vector2(160, 240)
	ribbon.size = Vector2(400, 70)
	ribbon.add_theme_stylebox_override("panel", _panel_style(CREAM, INK, 14, 6))
	screen_layer.add_child(ribbon)
	var subtitle := _label(_t("BRAND_SUBTITLE"), 33, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	ribbon.add_child(subtitle)

	var dragon := _texture_rect(DRAGON_TEXTURE, Rect2(178, 312, 364, 318), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	screen_layer.add_child(dragon)

	var prompt_panel := Panel.new()
	prompt_panel.position = Vector2(42, 635)
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
	shop_button.disabled = true
	screen_layer.add_child(shop_button)
	_add_button_caption(shop_button, _t("COMING_SOON"))

	var contest_button := _button(_t("NAV_CONTEST"), Rect2(372, 972, 276, 118), GOLD, Color("#d38a38"))
	contest_button.pressed.connect(_show_competition)
	screen_layer.add_child(contest_button)
	_add_button_caption(contest_button, _t("CONTEST_CAPTION"))

	var footer := _label(_t("FOOTER"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	footer.position = Vector2(0, canvas_size.y - 105)
	footer.size = Vector2(720, 40)
	screen_layer.add_child(footer)


func _show_den() -> void:
	_clear_screen()
	current_screen = "den"
	var sky := PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)

	var back := _small_button("‹", Rect2(32, 44, 78, 72), CREAM)
	back.pressed.connect(_show_main_menu)
	screen_layer.add_child(back)

	var title := _label(_t("DEN_TITLE"), 47, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(112, 46)
	title.size = Vector2(496, 67)
	screen_layer.add_child(title)

	var count := _label(_t("DEN_COUNT", {"owned": 1, "capacity": 12}), 22, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	count.position = Vector2(0, 130)
	count.size = Vector2(720, 34)
	screen_layer.add_child(count)

	var info := Panel.new()
	info.position = Vector2(40, 184)
	info.size = Vector2(640, 90)
	info.add_theme_stylebox_override("panel", _panel_style(Color("#fff1c9"), INK, 14, 5))
	screen_layer.add_child(info)
	var info_text := _label(_t("DEN_INSTRUCTION"), 25, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	info_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	info.add_child(info_text)

	var card := Button.new()
	card.position = Vector2(48, 310)
	card.size = Vector2(624, 650)
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("normal", _panel_style(WHITE, INK, 22, 9))
	card.add_theme_stylebox_override("hover", _panel_style(Color("#fff9de"), PINK_DARK, 22, 9))
	card.add_theme_stylebox_override("pressed", _panel_style(CREAM, PINK_DARK, 22, 3))
	card.pressed.connect(_show_habitat)
	screen_layer.add_child(card)

	var rarity := _badge(_t("STARTER"), Rect2(24, 22, 138, 44), PINK, WHITE)
	card.add_child(rarity)
	var happy := _badge(_t("HAPPY_HEART"), Rect2(416, 22, 178, 44), Color("#8ed5aa"), INK)
	card.add_child(happy)

	var portrait_back := Panel.new()
	portrait_back.position = Vector2(42, 86)
	portrait_back.size = Vector2(540, 340)
	portrait_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_back.add_theme_stylebox_override("panel", _panel_style(Color("#bdeaf7"), INK, 18, 4))
	card.add_child(portrait_back)
	var portrait := _texture_rect(DRAGON_TEXTURE, Rect2(110, 12, 320, 310), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_back.add_child(portrait)

	var name := _label(_t("DRAGON_NAME"), 55, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	name.position = Vector2(20, 446)
	name.size = Vector2(584, 68)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name)
	var details := _label(_t("LEVEL_SPECIES"), 24, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	details.position = Vector2(20, 512)
	details.size = Vector2(584, 36)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(details)
	var visit := _label(_t("VISIT_ISLAND"), 29, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	visit.position = Vector2(20, 578)
	visit.size = Vector2(584, 45)
	visit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(visit)

	var note := _label(_t("DEN_NOTE"), 23, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	note.position = Vector2(45, 1010)
	note.size = Vector2(630, 70)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_layer.add_child(note)


func _show_habitat() -> void:
	_clear_screen()
	current_screen = "habitat"
	bob_time = 0.0
	var sky_fill := ColorRect.new()
	sky_fill.position = Vector2.ZERO
	sky_fill.size = canvas_size
	sky_fill.color = SKY
	screen_layer.add_child(sky_fill)
	var background := _texture_rect(ISLAND_TEXTURE, Rect2(0, 0, canvas_size.x, canvas_size.y), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	screen_layer.add_child(background)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, 32)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 2000
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.94), INK, 18, 6))
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_show_den)
	top_panel.add_child(back)
	var name := _label(_t("ISLAND_TITLE"), 38, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	name.position = Vector2(92, 13)
	name.size = Vector2(470, 48)
	top_panel.add_child(name)
	var level := _label(_t("LEVEL_SPECIES"), 20, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	level.position = Vector2(92, 59)
	level.size = Vector2(470, 28)
	top_panel.add_child(level)
	var hearts := _label("♥", 35, PINK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	hearts.position = Vector2(580, 21)
	hearts.size = Vector2(65, 50)
	top_panel.add_child(hearts)

	var tip := Panel.new()
	tip.position = Vector2(116, 157)
	tip.size = Vector2(488, 62)
	tip.z_index = 2000
	tip.add_theme_stylebox_override("panel", _panel_style(Color(0.19, 0.13, 0.25, 0.88), INK, 12, 3))
	screen_layer.add_child(tip)
	var tip_text := _label(_t("HABITAT_TIP"), 23, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	tip_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	tip.add_child(tip_text)
	var tip_berry := BerryPickup.new()
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

	dragon_shadow = BlobShadow.new()
	dragon_shadow.position = Vector2(30, 199)
	dragon_shadow.size = Vector2(150, 38)
	dragon_actor.add_child(dragon_shadow)

	dragon_sprite = _texture_rect(DRAGON_TEXTURE, Rect2(0, 0, 250, 224), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
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
	clean_label = _label("%d%%" % cleanliness, 21, INK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
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
	_add_button_caption(groom_button, _t("GROOM_CAPTION"))


func _show_grooming() -> void:
	_clear_screen()
	current_screen = "groom"
	var height_mix := clampf((canvas_size.y - 1280.0) / (BASE_DESIGN_HEIGHT - 1280.0), 0.0, 1.0)
	var portrait_height := lerpf(560.0, 738.0, height_mix)
	var sprite_height := portrait_height - 88.0
	var portrait_bottom := 398.0 + portrait_height
	var hint_y := portrait_bottom + 20.0
	var complete_y := hint_y + 80.0
	var done_y := canvas_size.y - 142.0

	var sky := PixelSky.new()
	sky.position = Vector2.ZERO
	sky.size = canvas_size
	screen_layer.add_child(sky)
	var wash := ColorRect.new()
	wash.position = Vector2.ZERO
	wash.size = canvas_size
	wash.color = Color(1.0, 0.72, 0.84, 0.23)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(wash)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, 32)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.97), INK, 18, 6))
	screen_layer.add_child(top_panel)
	var back := _small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_show_habitat)
	top_panel.add_child(back)
	var title := _label(_t("GROOM_TITLE"), 40, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	title.position = Vector2(98, 14)
	title.size = Vector2(474, 70)
	top_panel.add_child(title)

	var progress_panel := Panel.new()
	progress_panel.position = Vector2(40, 164)
	progress_panel.size = Vector2(640, 118)
	progress_panel.z_index = 100
	progress_panel.add_theme_stylebox_override("panel", _panel_style(WHITE, INK, 16, 5))
	screen_layer.add_child(progress_panel)
	var clean_title := _label(_t("CLEAN"), 25, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	clean_title.position = Vector2(22, 14)
	clean_title.size = Vector2(180, 34)
	progress_panel.add_child(clean_title)
	clean_label = _label("%d%%" % cleanliness, 25, PINK_DARK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
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
	instruction.position = Vector2(82, 306)
	instruction.size = Vector2(556, 66)
	instruction.z_index = 100
	instruction.add_theme_stylebox_override("panel", _panel_style(Color(0.19, 0.13, 0.25, 0.92), INK, 12, 3))
	screen_layer.add_child(instruction)
	var instruction_text := _label(_t("GROOM_INSTRUCTION"), 24, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	instruction_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	instruction.add_child(instruction_text)

	var portrait_panel := Panel.new()
	portrait_panel.position = Vector2(40, 398)
	portrait_panel.size = Vector2(640, portrait_height)
	portrait_panel.clip_contents = true
	portrait_panel.add_theme_stylebox_override("panel", _panel_style(Color("#bdeaf7"), INK, 22, 7))
	screen_layer.add_child(portrait_panel)

	groom_sprite = _texture_rect(DRAGON_TEXTURE, Rect2(90, 420, 540, sprite_height), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
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

	groom_comb = PixelComb.new()
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
	done.pressed.connect(_show_habitat)
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
		cleanliness = mini(100, cleanliness + ceili(drag_delta.length() * 0.055))
		if cleanliness != previous_cleanliness:
			_update_clean_display()
			_spawn_groom_sparkle(groom_area.position + local_position)
		_update_continuous_stretch(drag_delta)


func _is_over_dragon(local_position: Vector2) -> bool:
	if dragon_alpha_image == null or not is_instance_valid(groom_area):
		return false
	var texture_size := Vector2(DRAGON_TEXTURE.get_width(), DRAGON_TEXTURE.get_height())
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
		clean_label.text = "%d%%" % cleanliness
	if is_instance_valid(groom_complete_label):
		groom_complete_label.visible = cleanliness >= 100


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
	_clear_screen()
	current_screen = "competition"
	var judge_y := canvas_size.y - 142.0
	var item_row_y := judge_y - 170.0
	var stage_height := minf(760.0, item_row_y - 315.0)
	var stage_scale := minf(1.0, stage_height / 720.0)

	var sky := PixelSky.new()
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

	var sword := AccessoryArt.new("sword")
	sword.position = accessory_positions["sword"]
	sword.size = Vector2(92, 220)
	sword.rotation = 0.55
	stage_content.add_child(sword)
	_register_accessory("sword", sword)

	var hat := AccessoryArt.new("hat")
	hat.position = accessory_positions["hat"]
	hat.size = Vector2(120, 100)
	stage_content.add_child(hat)
	_register_accessory("hat", hat)

	var shield := AccessoryArt.new("shield")
	shield.position = accessory_positions["shield"]
	shield.size = Vector2(130, 150)
	stage_content.add_child(shield)
	_register_accessory("shield", shield)

	var bowtie := AccessoryArt.new("bowtie")
	bowtie.position = accessory_positions["bowtie"]
	bowtie.size = Vector2(92, 72)
	stage_content.add_child(bowtie)
	_register_accessory("bowtie", bowtie)

	var tie := AccessoryArt.new("tie")
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
	var icon := AccessoryArt.new(kind)
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
	var stars := _label("★★★★★", 57, GOLD, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	stars.position = Vector2(20, 176)
	stars.size = Vector2(560, 82)
	stars.add_theme_color_override("font_outline_color", INK)
	stars.add_theme_constant_override("outline_size", 5)
	result_panel.add_child(stars)
	var score := _label("5 / 5", 47, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	score.position = Vector2(20, 256)
	score.size = Vector2(560, 68)
	result_panel.add_child(score)
	var comment := _label(_t("JUDGE_COMMENT"), 24, INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	comment.position = Vector2(58, 330)
	comment.size = Vector2(484, 90)
	comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_panel.add_child(comment)
	var continue_button := _button(_t("CONTINUE"), Rect2(80, 460, 440, 96), PINK, PINK_DARK)
	continue_button.pressed.connect(_close_competition_result)
	result_panel.add_child(continue_button)


func _close_competition_result() -> void:
	if is_instance_valid(competition_result_overlay):
		competition_result_overlay.queue_free()
	competition_result_overlay = null


func _feed_dragon() -> void:
	if walking or not is_instance_valid(dragon_actor):
		return
	walking = true
	feed_button.disabled = true
	var target := Vector2(
		random.randf_range(155.0, 565.0),
		random.randf_range(500.0 + _island_vertical_offset(), 790.0 + _island_vertical_offset())
	)
	var berry := BerryPickup.new()
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


func _add_resource_pill(position_value: Vector2, text_value: String, accent := PINK) -> void:
	var pill := Panel.new()
	pill.position = position_value
	pill.size = Vector2(172, 62)
	pill.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.98, 0.91, 0.92), INK, 14, 4))
	screen_layer.add_child(pill)
	var pill_text := _label(text_value, 24, accent, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	pill_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	pill.add_child(pill_text)


func _t(key: String, values: Dictionary = {}) -> String:
	return Localization.text(key, values)


func _on_locale_changed(_locale: String) -> void:
	_rebuild_current_screen()


func _rebuild_current_screen() -> void:
	match current_screen:
		"den":
			_show_den()
		"habitat":
			_show_habitat()
		"groom":
			_show_grooming()
		"competition":
			_show_competition()
		_:
			_show_main_menu()


func debug_groom_stroke() -> void:
	if current_screen != "groom":
		_show_grooming()
	grooming = true
	groom_drag_accumulator = Vector2.ZERO
	for index in 40:
		var point := groom_sprite.position - groom_area.position + Vector2(240 + (index % 4) * 22, groom_sprite.size.y * 0.54 + (index % 3) * 12)
		_groom_at(point, Vector2(58, 12))


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
	_show_competition()
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


func debug_show_screen(screen_name: String) -> void:
	match screen_name:
		"den":
			_show_den()
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
		"competition_dragged":
			debug_competition_drag()
		"result":
			selected_accessories["hat"] = true
			selected_accessories["bowtie"] = true
			_show_competition()
			_judge_competition()
		_:
			_show_main_menu()
