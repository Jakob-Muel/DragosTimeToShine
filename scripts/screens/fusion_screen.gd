extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const FUSION_CARD := preload("res://scripts/ui/fusion_dragon_card.gd")
const FUSION_STONE := preload("res://scripts/ui/fusion_stone.gd")
const LETTER_TRACE_PAD := preload("res://scripts/ui/letter_trace_pad.gd")
const LETTERS := ["F", "U", "S", "I", "O", "N"]

var first_parent_id := ""
var second_parent_id := ""
var letter_index := 0
var first_stone: Control
var second_stone: Control
var status_label: Label
var start_button: Button
var trace_pad: Control
var result_egg_id := ""


func build() -> void:
	_build_selection()


func _clear_content() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _add_background() -> float:
	var top_shift := safe_top_y(44.0) - 44.0
	var sky := PIXEL_ART.PixelSky.new()
	sky.size = canvas_size
	add_child(sky)
	return top_shift


func _add_header(back_callable: Callable, top_shift: float) -> void:
	var back := WidgetFactory.small_button("‹", Rect2(32, 44 + top_shift, 78, 72), UiTokens.CREAM)
	back.pressed.connect(back_callable)
	add_child(back)
	var title := WidgetFactory.label(
		tr_text("FUSION_TITLE"),
		47,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	title.position = Vector2(112, 46 + top_shift)
	title.size = Vector2(496, 67)
	add_child(title)
	var stars := WidgetFactory.badge(
		tr_text("FUSION_STARS", {"count": GameState.fusion_stars}),
		Rect2(236, 125 + top_shift, 248, 52),
		Color("#fff0aa"),
		Color("#864b9a")
	)
	add_child(stars)


func _build_selection() -> void:
	_clear_content()
	var top_shift := _add_background()
	_add_header(navigate.bind("den", {}), top_shift)

	var instruction := WidgetFactory.label(
		tr_text("FUSION_SELECT_INSTRUCTION"),
		25,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	instruction.position = Vector2(42, 191 + top_shift)
	instruction.size = Vector2(636, 62)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(instruction)

	first_stone = _make_stone(0, Vector2(45, 260 + top_shift))
	second_stone = _make_stone(1, Vector2(385, 260 + top_shift))
	_refresh_stones()

	status_label = WidgetFactory.label(
		tr_text("FUSION_DRAG_HINT"),
		22,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	status_label.position = Vector2(50, 555 + top_shift)
	status_label.size = Vector2(620, 64)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)

	start_button = WidgetFactory.button(
		tr_text("FUSION_START"),
		Rect2(90, 625 + top_shift, 540, 96),
		Color("#9a68bd"),
		Color("#67447f")
	)
	start_button.pressed.connect(_begin_trace)
	add_child(start_button)

	var collection_title := WidgetFactory.label(
		tr_text("FUSION_CHOOSE_DRAGONS"),
		27,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	collection_title.position = Vector2(40, 745 + top_shift)
	collection_title.size = Vector2(640, 45)
	add_child(collection_title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, 800 + top_shift)
	scroll.size = Vector2(664, maxf(350.0, canvas_size.y - 825.0 - top_shift))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var content := Control.new()
	var rows := ceili(GameState.dragons.size() / 2.0)
	content.custom_minimum_size = Vector2(640, maxf(330.0, rows * 285.0))
	scroll.add_child(content)
	for index in GameState.dragons.size():
		_add_dragon_card(content, GameState.dragons[index], index)
	_update_selection_state()


func _make_stone(index: int, at_position: Vector2) -> Control:
	var stone := FUSION_STONE.new()
	stone.slot_index = index
	stone.position = at_position
	stone.size = Vector2(290, 280)
	stone.dragon_dropped.connect(_on_dragon_placed)
	add_child(stone)
	return stone


func _add_dragon_card(parent: Control, dragon: Dictionary, index: int) -> void:
	var card := FUSION_CARD.new()
	card.dragon_id = String(dragon.get("id", ""))
	card.position = Vector2((index % 2) * 322.0, (index / 2) * 285.0)
	card.size = Vector2(305, 265)
	card.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color("#fffaf0"), UiTokens.INK, 16, 5)
	)
	card.dragon_tapped.connect(_on_dragon_tapped)
	parent.add_child(card)

	var texture := GameState.dragon_texture(dragon)
	if texture != null:
		var portrait := WidgetFactory.texture_rect(
			texture,
			Rect2(25, 12, 255, 185),
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		portrait.texture_filter = (
			CanvasItem.TEXTURE_FILTER_LINEAR
			if GameState.dragon_has_type(dragon, &"sunwing")
			else CanvasItem.TEXTURE_FILTER_NEAREST
		)
		card.add_child(portrait)
	var dragon_name := WidgetFactory.label(
		tr_text(GameState.dragon_name_key(dragon)),
		30,
		_dragon_accent(dragon),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	dragon_name.position = Vector2(8, 201)
	dragon_name.size = Vector2(289, 48)
	card.add_child(dragon_name)


func _dragon_accent(dragon: Dictionary) -> Color:
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"earth"):
		return Color("#d9571f")
	if GameState.dragon_has_type(dragon, &"earth") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#607d69")
	if GameState.dragon_has_type(dragon, &"fire") and GameState.dragon_has_type(dragon, &"water"):
		return Color("#824ca0")
	if GameState.dragon_has_type(dragon, &"fire"):
		return Color("#d8492f")
	if GameState.dragon_has_type(dragon, &"water"):
		return Color("#168ec8")
	if GameState.dragon_has_type(dragon, &"earth"):
		return Color("#8b633d")
	return UiTokens.PINK_DARK


func _on_dragon_tapped(dragon_id: String) -> void:
	if dragon_id == first_parent_id:
		first_parent_id = ""
	elif dragon_id == second_parent_id:
		second_parent_id = ""
	elif first_parent_id.is_empty():
		first_parent_id = dragon_id
	else:
		second_parent_id = dragon_id
	_refresh_stones()
	_update_selection_state()


func _on_dragon_placed(slot_index: int, dragon_id: String) -> void:
	if slot_index == 0:
		first_parent_id = dragon_id
		if second_parent_id == dragon_id:
			second_parent_id = ""
	else:
		second_parent_id = dragon_id
		if first_parent_id == dragon_id:
			first_parent_id = ""
	_refresh_stones()
	_update_selection_state()


func _refresh_stones() -> void:
	_refresh_stone(first_stone, first_parent_id)
	_refresh_stone(second_stone, second_parent_id)


func _refresh_stone(stone: Control, dragon_id: String) -> void:
	for child in stone.get_children():
		stone.remove_child(child)
		child.queue_free()
	stone.occupied = not dragon_id.is_empty()
	if dragon_id.is_empty():
		var empty := WidgetFactory.label(
			tr_text("FUSION_STONE_EMPTY"),
			24,
			Color("#fff1c9"),
			HORIZONTAL_ALIGNMENT_CENTER,
			UiTokens.FONT_BOLD
		)
		empty.position = Vector2(25, 170)
		empty.size = Vector2(240, 58)
		stone.add_child(empty)
		return
	var dragon := GameState.get_dragon(dragon_id)
	var texture := GameState.dragon_texture(dragon)
	if texture != null:
		var portrait := WidgetFactory.texture_rect(
			texture,
			Rect2(36, 0, 218, 190),
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		portrait.texture_filter = (
			CanvasItem.TEXTURE_FILTER_LINEAR
			if GameState.dragon_has_type(dragon, &"sunwing")
			else CanvasItem.TEXTURE_FILTER_NEAREST
		)
		stone.add_child(portrait)
	var name := WidgetFactory.label(
		tr_text(GameState.dragon_name_key(dragon)),
		28,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	name.position = Vector2(20, 192)
	name.size = Vector2(250, 50)
	stone.add_child(name)


func _update_selection_state() -> void:
	if start_button == null or status_label == null:
		return
	var error := GameState.fusion_eligibility_error(first_parent_id, second_parent_id)
	start_button.disabled = not error.is_empty()
	status_label.text = tr_text(_error_text_key(error))
	status_label.add_theme_color_override(
		"font_color",
		Color("#34815b") if error.is_empty() else UiTokens.INK_SOFT
	)


func _error_text_key(error: StringName) -> String:
	match error:
		&"missing_parent":
			return "FUSION_DRAG_HINT"
		&"same_parent":
			return "FUSION_DIFFERENT"
		&"no_recipe":
			return "FUSION_NO_RECIPE"
		&"already_owned":
			return "FUSION_ALREADY_OWNED"
		&"fusion_pending":
			return "FUSION_PENDING"
		&"den_full":
			return "FUSION_DEN_FULL"
		&"not_enough_stars":
			return "FUSION_NEED_STAR"
	return "FUSION_READY"


func _begin_trace() -> void:
	if not GameState.can_fuse(first_parent_id, second_parent_id):
		_update_selection_state()
		return
	letter_index = 0
	_build_trace()


func _build_trace() -> void:
	_clear_content()
	var top_shift := _add_background()
	_add_header(_build_selection, top_shift)

	var word_panel := Panel.new()
	word_panel.position = Vector2(54, 200 + top_shift)
	word_panel.size = Vector2(612, 124)
	word_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color("#fff8e8"), UiTokens.INK, 16, 5)
	)
	add_child(word_panel)
	for index in LETTERS.size():
		var color := UiTokens.INK_SOFT
		if index < letter_index:
			color = Color("#45a46a")
		elif index == letter_index:
			color = Color("#d8492f")
		var letter := WidgetFactory.label(
			LETTERS[index],
			62,
			color,
			HORIZONTAL_ALIGNMENT_CENTER,
			UiTokens.FONT_BOLD
		)
		letter.position = Vector2(18 + index * 96, 10)
		letter.size = Vector2(84, 96)
		word_panel.add_child(letter)

	var instruction := WidgetFactory.label(
		tr_text("FUSION_TRACE_INSTRUCTION", {"letter": LETTERS[letter_index]}),
		28,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	instruction.position = Vector2(40, 346 + top_shift)
	instruction.size = Vector2(640, 68)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(instruction)

	trace_pad = LETTER_TRACE_PAD.new()
	trace_pad.position = Vector2(60, 430 + top_shift)
	trace_pad.size = Vector2(600, minf(720.0, canvas_size.y - 545.0 - top_shift))
	trace_pad.set_letter(LETTERS[letter_index])
	trace_pad.letter_completed.connect(_on_letter_completed)
	add_child(trace_pad)

	var hint := WidgetFactory.label(
		tr_text("FUSION_TRACE_HINT"),
		21,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	hint.position = Vector2(50, trace_pad.position.y + trace_pad.size.y + 12)
	hint.size = Vector2(620, 52)
	add_child(hint)


func _on_letter_completed(_letter: String) -> void:
	letter_index += 1
	if letter_index < LETTERS.size():
		_build_trace()
		return
	_complete_fusion()


func _complete_fusion() -> void:
	result_egg_id = GameState.fuse_dragons(first_parent_id, second_parent_id)
	if result_egg_id.is_empty():
		_build_selection()
		return
	_build_reveal()


func _build_reveal() -> void:
	_clear_content()
	var top_shift := _add_background()
	var burst := Panel.new()
	burst.position = Vector2(44, 104 + top_shift)
	burst.size = Vector2(632, 1170)
	burst.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color("#fff2c4"), Color("#70438b"), 28, 10)
	)
	add_child(burst)
	var complete := WidgetFactory.label(
		tr_text("FUSION_COMPLETE"),
		48,
		Color("#824ca0"),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	complete.position = Vector2(15, 45)
	complete.size = Vector2(602, 74)
	burst.add_child(complete)
	var star := WidgetFactory.label(
		"✦",
		68,
		Color("#f0a126"),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	star.position = Vector2(0, 118)
	star.size = Vector2(632, 72)
	burst.add_child(star)
	var result := GameState.get_egg(result_egg_id)
	var texture := GameState.egg_texture(result)
	if texture != null:
		var portrait := WidgetFactory.texture_rect(
			texture,
			Rect2(96, 195, 440, 600),
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		burst.add_child(portrait)
	var result_name := tr_text(GameState.egg_name_key(result))
	var created := WidgetFactory.label(
		tr_text("FUSION_EGG_CREATED", {"name": result_name}),
		38,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	created.position = Vector2(25, 805)
	created.size = Vector2(582, 76)
	created.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	burst.add_child(created)
	var species := WidgetFactory.label(
		tr_text("FUSION_EGG_STEP_GOAL", {"required": GameState.FUSION_EGG_REQUIRED_STEPS}),
		25,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	species.position = Vector2(25, 881)
	species.size = Vector2(582, 52)
	burst.add_child(species)
	var view := WidgetFactory.button(
		tr_text("FUSION_VIEW_EGGS"),
		Rect2(66, 966, 500, 112),
		Color("#45a5b8"),
		Color("#267487")
	)
	view.pressed.connect(navigate.bind("eggs", {}))
	burst.add_child(view)


func debug_select_parents() -> void:
	for dragon: Dictionary in GameState.dragons:
		if GameState.dragon_has_type(dragon, &"fire") and not GameState.dragon_has_type(dragon, &"water"):
			first_parent_id = String(dragon.get("id", ""))
		elif GameState.dragon_has_type(dragon, &"water") and not GameState.dragon_has_type(dragon, &"fire"):
			second_parent_id = String(dragon.get("id", ""))
	_refresh_stones()
	_update_selection_state()


func debug_begin_trace() -> void:
	_begin_trace()


func debug_complete_letter() -> void:
	if trace_pad != null and is_instance_valid(trace_pad):
		trace_pad.debug_complete()


func debug_complete_all() -> void:
	if not GameState.can_fuse(first_parent_id, second_parent_id):
		return
	letter_index = LETTERS.size()
	_complete_fusion()
