extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const SEEDED_DRAGON := preload("res://scripts/ui/seeded_dragon.gd")
const MIN_SEED := 1
const MAX_SEED := 100

var current_seed := 37
var dragon: SeededDragon
var name_label: Label
var seed_label: Label
var rarity_badge: Panel
var trait_values: Dictionary = {}


func build() -> void:
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)

	_build_header()
	_build_stage()
	_build_trait_panel()
	_build_controls()
	_show_seed(current_seed)


func _build_header() -> void:
	var top_y := safe_top_y(28.0)
	var back := WidgetFactory.small_button("‹", Rect2(28, top_y, 78, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("main", {}))
	add_child(back)

	var title := WidgetFactory.label(
		tr_text("DRAGON_LAB_TITLE"),
		40,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_HEAVY
	)
	title.position = Vector2(118, top_y)
	title.size = Vector2(574, 60)
	add_child(title)

	var subtitle := WidgetFactory.label(
		tr_text("DRAGON_LAB_SUBTITLE"),
		21,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	subtitle.position = Vector2(116, top_y + 50)
	subtitle.size = Vector2(578, 38)
	add_child(subtitle)


func _build_stage() -> void:
	var stage := Panel.new()
	stage.position = Vector2(50, 138)
	stage.size = Vector2(620, 650)
	stage.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color("#fffaf0"), UiTokens.PINK_DARK, 24, 9)
	)
	add_child(stage)

	name_label = WidgetFactory.label(
		"",
		37,
		UiTokens.PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_HEAVY
	)
	name_label.position = Vector2(28, 18)
	name_label.size = Vector2(564, 56)
	stage.add_child(name_label)

	seed_label = WidgetFactory.label(
		"",
		20,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_NUMERIC
	)
	seed_label.position = Vector2(120, 69)
	seed_label.size = Vector2(380, 34)
	stage.add_child(seed_label)

	dragon = SEEDED_DRAGON.new() as SeededDragon
	dragon.name = "SeededDragonPreview"
	dragon.position = Vector2(48, 92)
	dragon.size = Vector2(524, 535)
	stage.add_child(dragon)

	rarity_badge = WidgetFactory.badge(
		tr_text("DRAGON_LAB_RARE"),
		Rect2(430, 106, 150, 48),
		UiTokens.GOLD,
		UiTokens.INK
	)
	rarity_badge.visible = false
	rarity_badge.z_index = 10
	stage.add_child(rarity_badge)


func _build_trait_panel() -> void:
	var panel := Panel.new()
	panel.position = Vector2(50, 808)
	panel.size = Vector2(620, 236)
	panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color("#fff1d2"), UiTokens.INK, 18, 6)
	)
	add_child(panel)

	var heading := WidgetFactory.label(
		tr_text("DRAGON_LAB_GENES"),
		23,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_HEAVY
	)
	heading.position = Vector2(18, 12)
	heading.size = Vector2(584, 38)
	panel.add_child(heading)

	var traits := [
		["palette", "DRAGON_LAB_COLOR", Vector2(28, 54)],
		["body", "DRAGON_LAB_BODY", Vector2(318, 54)],
		["wings", "DRAGON_LAB_WINGS", Vector2(28, 112)],
		["horns", "DRAGON_LAB_HORNS", Vector2(318, 112)],
		["pattern", "DRAGON_LAB_PATTERN", Vector2(28, 170)],
		["tail", "DRAGON_LAB_TAIL", Vector2(318, 170)],
	]
	for trait_row in traits:
		var key: String = trait_row[0]
		var position_value: Vector2 = trait_row[2]
		var caption := WidgetFactory.label(
			tr_text(trait_row[1]),
			17,
			UiTokens.INK_SOFT,
			HORIZONTAL_ALIGNMENT_LEFT,
			UiTokens.FONT_BOLD
		)
		caption.position = position_value
		caption.size = Vector2(104, 44)
		panel.add_child(caption)

		var value := WidgetFactory.label(
			"",
			19,
			UiTokens.PINK_DARK,
			HORIZONTAL_ALIGNMENT_LEFT,
			UiTokens.FONT_HEAVY
		)
		value.position = position_value + Vector2(106, 0)
		value.size = Vector2(166, 44)
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		panel.add_child(value)
		trait_values[key] = value


func _build_controls() -> void:
	var y := 1068.0
	var previous := WidgetFactory.button(
		tr_text("DRAGON_LAB_PREVIOUS"),
		Rect2(50, y, 150, 88),
		UiTokens.CREAM,
		UiTokens.CREAM_DEEP
	)
	previous.add_theme_font_size_override("font_size", 23)
	previous.pressed.connect(_change_seed.bind(-1))
	add_child(previous)

	var randomize := WidgetFactory.button(
		tr_text("DRAGON_LAB_RANDOMIZE"),
		Rect2(218, y, 284, 88),
		UiTokens.PINK,
		UiTokens.PINK_DARK
	)
	randomize.add_theme_font_size_override("font_size", 25)
	randomize.pressed.connect(_randomize)
	add_child(randomize)

	var next := WidgetFactory.button(
		tr_text("DRAGON_LAB_NEXT"),
		Rect2(520, y, 150, 88),
		UiTokens.CREAM,
		UiTokens.CREAM_DEEP
	)
	next.add_theme_font_size_override("font_size", 23)
	next.pressed.connect(_change_seed.bind(1))
	add_child(next)

	var hint := WidgetFactory.label(
		tr_text("DRAGON_LAB_HINT"),
		19,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	hint.position = Vector2(42, y + 102)
	hint.size = Vector2(636, 66)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)


func _change_seed(delta: int) -> void:
	var next_seed := current_seed + delta
	if next_seed < MIN_SEED:
		next_seed = MAX_SEED
	elif next_seed > MAX_SEED:
		next_seed = MIN_SEED
	_show_seed(next_seed)


func _randomize() -> void:
	var next_seed := randi_range(MIN_SEED, MAX_SEED)
	if next_seed == current_seed:
		next_seed = MIN_SEED + (next_seed % MAX_SEED)
	_show_seed(next_seed)


func _show_seed(value: int) -> void:
	current_seed = clampi(value, MIN_SEED, MAX_SEED)
	dragon.set_seed(current_seed)
	var traits := dragon.trait_summary()
	name_label.text = String(traits["name"]).to_upper()
	seed_label.text = tr_text(
		"DRAGON_LAB_SEED",
		{"seed": "%03d" % current_seed, "total": MAX_SEED}
	)
	rarity_badge.visible = bool(traits["rare"])
	trait_values["palette"].text = String(traits["palette_name"])
	trait_values["body"].text = String(traits["body_name"])
	trait_values["wings"].text = String(traits["wing_name"])
	trait_values["horns"].text = String(traits["horn_name"])
	trait_values["pattern"].text = String(traits["pattern_name"])
	trait_values["tail"].text = String(traits["tail_name"])


func debug_set_seed(value: int) -> void:
	_show_seed(value)
