extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const DRAGON_TEXTURE := preload("res://assets/art/dragon_pink_hd.png")
const ISLAND_TEXTURE := preload("res://assets/art/dragon_island_hd.png")
const ICE_DRAGON_TEXTURE := preload("res://assets/art/ice/ice_dragon_alpha.png")
const ICE_ISLAND_TEXTURE := preload("res://assets/art/ice/ice_island_hd.png")
const SUNBERRY_TEXTURE := preload("res://assets/art/ui_redesign/icons/sunberry.png")
const GROOMING_COMB_TEXTURE := preload("res://assets/art/ui_redesign/icons/grooming_comb.png")
const DRAGON_FOOT_ANCHOR := Vector2(105.0, 218.0)

const PINK := UiTokens.PINK
const PINK_DARK := UiTokens.PINK_DARK
const CREAM := UiTokens.CREAM
const SKY := UiTokens.SKY
const MINT := UiTokens.MINT
const INK := UiTokens.INK
const INK_SOFT := UiTokens.INK_SOFT
const WHITE := UiTokens.WHITE
const GOLD := UiTokens.GOLD
const FONT_BOLD := UiTokens.FONT_BOLD

var selected_dragon_id := "luma"
var active_dragon_texture: Texture2D = DRAGON_TEXTURE
var active_island_texture: Texture2D = ISLAND_TEXTURE
var dragon_actor: Control
var dragon_presentation: Control
var feed_button: Button
var hunger_bar: ProgressBar
var hunger_label: Label
var clean_bar: ProgressBar
var clean_label: Label
var care_label: Label
var groom_button: Button
var walking := false
var bob_time := 0.0
var random := RandomNumberGenerator.new()

var hunger: int:
	get:
		return GameState.get_dragon_hunger(selected_dragon_id)
	set(value):
		GameState.set_dragon_hunger(selected_dragon_id, value)
var cleanliness: float:
	get:
		return GameState.get_dragon_cleanliness(selected_dragon_id)
var care_points: int:
	get:
		return GameState.get_dragon_care_points(selected_dragon_id)
	set(value):
		GameState.set_dragon_care_points(selected_dragon_id, value)


func _process(delta: float) -> void:
	if not is_instance_valid(dragon_presentation):
		return
	bob_time += delta
	var amplitude := 11.0 if walking else 4.0
	var speed := 13.0 if walking else 3.2
	var bounce: float = abs(sin(bob_time * speed)) * amplitude
	dragon_presentation.call("set_bounce", bounce)


func selected_dragon_data() -> Dictionary:
	return GameState.get_dragon(selected_dragon_id)


func selected_dragon_name() -> String:
	return tr_text(GameState.dragon_name_key(selected_dragon_data()))


func dragon_texture_for(dragon_data: Dictionary) -> Texture2D:
	var texture := GameState.dragon_texture(dragon_data)
	if texture != null:
		return texture
	return ICE_DRAGON_TEXTURE if GameState.dragon_has_type(dragon_data, &"ice") else DRAGON_TEXTURE


func island_texture_for(dragon_data: Dictionary) -> Texture2D:
	var texture := GameState.island_texture(dragon_data)
	if texture != null:
		return texture
	return ICE_ISLAND_TEXTURE if GameState.dragon_has_type(dragon_data, &"ice") else ISLAND_TEXTURE


func island_vertical_offset() -> float:
	return clampf((canvas_size.y - 1280.0) * 0.5, 0.0, 180.0)


func _go_dragons() -> void:
	navigate("dragons")


func _go_groom() -> void:
	navigate("groom", {"selected_dragon_id": selected_dragon_id})

func build() -> void:
	selected_dragon_id = String(context.get("selected_dragon_id", "luma"))
	random.randomize()
	var top_shift := safe_top_y(32.0) - 32.0
	bob_time = 0.0
	var dragon_data := selected_dragon_data()
	var uses_pixel_filter := not GameState.dragon_has_type(dragon_data, &"sunwing")
	var accent := _dragon_accent_color(dragon_data)
	active_dragon_texture = dragon_texture_for(dragon_data)
	active_island_texture = island_texture_for(dragon_data)
	var sky_fill := ColorRect.new()
	sky_fill.position = Vector2.ZERO
	sky_fill.size = canvas_size
	sky_fill.color = _habitat_sky_color(dragon_data)
	add_child(sky_fill)
	var background := WidgetFactory.texture_rect(
		active_island_texture,
		Rect2(0, 0, canvas_size.x, canvas_size.y),
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if uses_pixel_filter else CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, 32 + top_shift)
	top_panel.size = Vector2(672, 104)
	top_panel.z_index = 2000
	top_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(_habitat_panel_color(dragon_data), INK, 18, 6)
	)
	add_child(top_panel)
	var back := WidgetFactory.small_button("‹", Rect2(16, 16, 74, 68), CREAM)
	back.pressed.connect(_go_dragons)
	top_panel.add_child(back)
	var active_dragon_name := selected_dragon_name()
	var name := WidgetFactory.label(tr_text("DRAGON_ISLAND_TITLE", {"name": active_dragon_name}), 38, INK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	name.position = Vector2(92, 13)
	name.size = Vector2(470, 48)
	top_panel.add_child(name)
	var level := WidgetFactory.label(
		tr_text(GameState.dragon_level_species_key(dragon_data)),
		20,
		INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		FONT_BOLD
	)
	level.position = Vector2(92, 59)
	level.size = Vector2(470, 28)
	top_panel.add_child(level)
	var hearts := WidgetFactory.label("♥", 35, accent, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	hearts.position = Vector2(580, 21)
	hearts.size = Vector2(65, 50)
	top_panel.add_child(hearts)

	var tip := Panel.new()
	tip.position = Vector2(116, 157 + top_shift)
	tip.size = Vector2(488, 62)
	tip.z_index = 2000
	tip.add_theme_stylebox_override("panel", WidgetFactory.panel_style(Color(0.19, 0.13, 0.25, 0.88), INK, 12, 3))
	add_child(tip)
	var tip_text := WidgetFactory.label(tr_text("HABITAT_TIP_DYNAMIC", {"name": active_dragon_name}), 23, WHITE, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	tip_text.position = Vector2(62, 0)
	tip_text.size = Vector2(412, 62)
	tip.add_child(tip_text)
	var tip_berry := WidgetFactory.pixel_icon(SUNBERRY_TEXTURE, Rect2(12, 7, 48, 48))
	tip.add_child(tip_berry)

	dragon_actor = Control.new()
	dragon_actor.position = Vector2(255, 407 + island_vertical_offset())
	dragon_actor.size = Vector2(250, 250)
	dragon_actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dragon_actor.z_index = 650
	add_child(dragon_actor)

	dragon_presentation = WidgetFactory.dragon_presentation(
		active_dragon_texture,
		Rect2(0, 0, 250, 224),
		CanvasItem.TEXTURE_FILTER_NEAREST
		if uses_pixel_filter
		else CanvasItem.TEXTURE_FILTER_LINEAR
	)
	dragon_actor.add_child(dragon_presentation)

	var bottom := Panel.new()
	bottom.position = Vector2(24, canvas_size.y - 456)
	bottom.size = Vector2(672, 420)
	bottom.z_index = 2000
	bottom.add_theme_stylebox_override("panel", WidgetFactory.panel_style(Color(1, 0.98, 0.91, 0.97), INK, 22, 9))
	add_child(bottom)

	var mood_title := WidgetFactory.label(tr_text("MOOD"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	mood_title.position = Vector2(26, 18)
	mood_title.size = Vector2(120, 30)
	bottom.add_child(mood_title)
	var mood := WidgetFactory.label(tr_text("HAPPY_THREE"), 28, PINK_DARK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	mood.position = Vector2(350, 12)
	mood.size = Vector2(288, 40)
	bottom.add_child(mood)

	var hunger_icon := WidgetFactory.pixel_icon(SUNBERRY_TEXTURE, Rect2(24, 61, 30, 30))
	bottom.add_child(hunger_icon)
	var hunger_title := WidgetFactory.label(tr_text("HUNGER"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	hunger_title.position = Vector2(62, 64)
	hunger_title.size = Vector2(140, 30)
	bottom.add_child(hunger_title)
	hunger_label = WidgetFactory.label("%d%%" % hunger, 21, INK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	hunger_label.position = Vector2(542, 64)
	hunger_label.size = Vector2(96, 30)
	bottom.add_child(hunger_label)
	hunger_bar = ProgressBar.new()
	hunger_bar.position = Vector2(26, 98)
	hunger_bar.size = Vector2(612, 32)
	hunger_bar.value = hunger
	hunger_bar.show_percentage = false
	hunger_bar.add_theme_stylebox_override("background", WidgetFactory.panel_style(Color("#e3d4b8"), INK, 8, 0))
	hunger_bar.add_theme_stylebox_override("fill", WidgetFactory.panel_style(GOLD, INK, 8, 0))
	bottom.add_child(hunger_bar)

	var clean_icon := WidgetFactory.pixel_icon(GROOMING_COMB_TEXTURE, Rect2(22, 143, 34, 28))
	bottom.add_child(clean_icon)
	var clean_title := WidgetFactory.label(tr_text("CLEAN"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	clean_title.position = Vector2(62, 145)
	clean_title.size = Vector2(140, 30)
	bottom.add_child(clean_title)
	clean_label = WidgetFactory.label("%d%%" % floori(cleanliness), 21, INK, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	clean_label.position = Vector2(542, 145)
	clean_label.size = Vector2(96, 30)
	bottom.add_child(clean_label)
	clean_bar = ProgressBar.new()
	clean_bar.position = Vector2(26, 179)
	clean_bar.size = Vector2(612, 32)
	clean_bar.value = cleanliness
	clean_bar.show_percentage = false
	clean_bar.add_theme_stylebox_override("background", WidgetFactory.panel_style(Color("#e3d4b8"), INK, 8, 0))
	clean_bar.add_theme_stylebox_override("fill", WidgetFactory.panel_style(MINT, INK, 8, 0))
	bottom.add_child(clean_bar)

	care_label = WidgetFactory.label(tr_text("CARE_POINTS", {"value": care_points}), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, FONT_BOLD)
	care_label.position = Vector2(26, 229)
	care_label.size = Vector2(270, 32)
	bottom.add_child(care_label)
	var inventory := WidgetFactory.label(tr_text("SUNBERRIES"), 21, INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT, FONT_BOLD)
	inventory.position = Vector2(350, 229)
	inventory.size = Vector2(288, 32)
	bottom.add_child(inventory)
	var action_divider := ColorRect.new()
	action_divider.position = Vector2(26, 260)
	action_divider.size = Vector2(612, 3)
	action_divider.color = Color(INK, 0.18)
	action_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(action_divider)

	feed_button = WidgetFactory.button(tr_text("FEED"), Rect2(26, 276, 294, 108), PINK, PINK_DARK)
	feed_button.pressed.connect(_feed_dragon)
	bottom.add_child(feed_button)
	WidgetFactory.add_button_caption(feed_button, tr_text("FEED_CAPTION"), SUNBERRY_TEXTURE)

	groom_button = WidgetFactory.button(tr_text("GROOM"), Rect2(344, 276, 294, 108), Color("#8ed5aa"), Color("#4d9a70"))
	groom_button.pressed.connect(_go_groom)
	bottom.add_child(groom_button)
	WidgetFactory.add_button_caption(
		groom_button,
		tr_text("GROOM_CAPTION_DYNAMIC", {"name": active_dragon_name}),
		GROOMING_COMB_TEXTURE
	)


func _dragon_accent_color(dragon: Dictionary) -> Color:
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"earth"):
		return Color("#f05a24")
	if GameState.dragon_has_type(dragon, &"earth") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#6f8d78")
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#9a68bd")
	if GameState.dragon_has_type(dragon, &"fire"):
		return Color("#ef6a32")
	if GameState.dragon_has_type(dragon, &"water"):
		return Color("#39b7df")
	if GameState.dragon_has_type(dragon, &"earth"):
		return Color("#c58a42")
	if GameState.dragon_has_type(dragon, &"ice"):
		return Color("#55bde8")
	return PINK


func _habitat_sky_color(dragon: Dictionary) -> Color:
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"earth"):
		return Color("#ff8a3d")
	if GameState.dragon_has_type(dragon, &"earth") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#b9c7ac")
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#73c8d6")
	if GameState.dragon_has_type(dragon, &"fire"):
		return Color("#ff9a48")
	if GameState.dragon_has_type(dragon, &"water"):
		return Color("#72ddf5")
	if GameState.dragon_has_type(dragon, &"earth"):
		return Color("#f4c66e")
	if GameState.dragon_has_type(dragon, &"ice"):
		return Color("#bcecff")
	return SKY


func _habitat_panel_color(dragon: Dictionary) -> Color:
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"earth"):
		return Color("#ffead6ef")
	if GameState.dragon_has_type(dragon, &"earth") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#eef0dcef")
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#fff2dcef")
	if GameState.dragon_has_type(dragon, &"fire"):
		return Color("#fff0d8eF")
	if GameState.dragon_has_type(dragon, &"water"):
		return Color("#e7fffbef")
	if GameState.dragon_has_type(dragon, &"earth"):
		return Color("#fff0d4ef")
	if GameState.dragon_has_type(dragon, &"ice"):
		return Color("#eefcffef")
	return Color(1, 0.98, 0.91, 0.94)

func _feed_dragon() -> void:
	if walking or not is_instance_valid(dragon_actor):
		return
	walking = true
	feed_button.disabled = true
	var target := Vector2(
		random.randf_range(155.0, 565.0),
		random.randf_range(500.0 + island_vertical_offset(), 790.0 + island_vertical_offset())
	)
	var berry := WidgetFactory.pixel_icon(
		SUNBERRY_TEXTURE,
		Rect2(target - Vector2(32, 210), Vector2(64, 64))
	)
	berry.scale = Vector2(0.25, 0.25)
	berry.z_index = int(target.y) - 1
	add_child(berry)

	var drop := create_tween().set_parallel(true)
	drop.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.tween_property(berry, "position", target - Vector2(32, 32), 0.48)
	drop.tween_property(berry, "scale", Vector2.ONE, 0.32)
	await drop.finished
	if not is_instance_valid(dragon_actor) or not is_inside_tree():
		return

	var actor_target := target - DRAGON_FOOT_ANCHOR
	var distance := dragon_actor.position.distance_to(actor_target)
	var walk_duration := clampf(distance / 185.0, 0.7, 2.4)
	dragon_actor.z_index = int(target.y)
	var walk := create_tween()
	walk.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	walk.tween_property(dragon_actor, "position", actor_target, walk_duration)
	await walk.finished
	if not is_instance_valid(berry) or not is_inside_tree():
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
	care_label.text = tr_text("CARE_POINTS", {"value": care_points})
	GameState.save_game()
	show_care_pop(target)
	walking = false
	feed_button.disabled = false

func show_care_pop(at_position: Vector2) -> void:
	var pop := WidgetFactory.label(tr_text("CARE_POP"), 27, PINK_DARK, HORIZONTAL_ALIGNMENT_CENTER, FONT_BOLD)
	pop.position = at_position + Vector2(-90, -120)
	pop.size = Vector2(180, 44)
	pop.z_index = 1200
	pop.add_theme_color_override("font_outline_color", WHITE)
	pop.add_theme_constant_override("outline_size", 6)
	add_child(pop)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(pop, "position:y", pop.position.y - 75.0, 0.8)
	tween.tween_property(pop, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(pop.queue_free)

func _burst_confetti(parent: Control, origin: Vector2, piece_count: int, layer: int) -> void:
	var colors := [PINK, GOLD, MINT, SKY, Color("#9b7ede"), CREAM]
	for piece_index in piece_count:
		var piece := PIXEL_ART.ConfettiPiece.new()
		piece.position = origin + Vector2(random.randf_range(-18.0, 18.0), random.randf_range(-8.0, 8.0))
		piece.size = Vector2(random.randi_range(10, 17), random.randi_range(16, 27))
		piece.velocity = Vector2(random.randf_range(-330.0, 330.0), random.randf_range(-570.0, -280.0))
		piece.spin = random.randf_range(-9.0, 9.0)
		piece.piece_color = colors[piece_index % colors.size()]
		piece.z_index = layer
		parent.add_child(piece)
